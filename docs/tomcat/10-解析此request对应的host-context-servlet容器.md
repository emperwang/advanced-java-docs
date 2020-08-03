[TOC]

# 对request所对应的host-context-servlet的解析

从前面整个一个请求流程的分析下来，其实发现一个问题，一个请求所对应的host，context以及servlet都在request中记录好了，问题就在这里，request为什么会记录这个信息呢？如果一个请求过来就知道要请求谁，岂不是意味着所有的接口都暴露了吗？想想都可怕。

其实request中之所以保存了此些信息，那是因为在此request传递到容器中进行进一步处理时，就已经解析出这些信息并放入到request了。本篇就来说下此解析。

> org.apache.catalina.connector.CoyoteAdapter#service

此处理步骤在进入容器的前一步操作的，是在adaptor中解析的：

```java
// adapter 此是请求进入容器处理前的适配器
@Override
public void service(org.apache.coyote.Request req, org.apache.coyote.Response res)
    throws Exception {

    Request request = (Request) req.getNote(ADAPTER_NOTES);
    Response response = (Response) res.getNote(ADAPTER_NOTES);

    if (request == null) {
        // Create objects
        request = connector.createRequest();
        request.setCoyoteRequest(req);
        response = connector.createResponse();
        response.setCoyoteResponse(res);

        // Link objects
        request.setResponse(response);
        response.setRequest(request);

        // Set as notes
        req.setNote(ADAPTER_NOTES, request);
        res.setNote(ADAPTER_NOTES, response);

        // Set query string encoding
        req.getParameters().setQueryStringCharset(connector.getURICharset());
    }
    // 补充header
    if (connector.getXpoweredBy()) {
        response.addHeader("X-Powered-By", POWERED_BY);
    }

    boolean async = false;
    boolean postParseSuccess = false;
    req.getRequestProcessor().setWorkerThreadName(THREAD_NAME.get());
    try {
        // Parse and set Catalina and configuration specific
        // request parameters
        // todo 重要
        // 1. 解析请求参数
        // 2. 解析schema
        // 3. 解析对应的host container
        // 4. 解析对应的context container
        // 5. 解析对应的servlet
        postParseSuccess = postParseRequest(req, request, res, response);
        if (postParseSuccess) {
            //check valves if we support async
            request.setAsyncSupported(
                connector.getService().getContainer().getPipeline().isAsyncSupported());
            // Calling the container
            // todo  重点 重点  此时转换后的request和response就会进入到容器中进行进一步的处理
            connector.getService().getContainer().getPipeline().getFirst().invoke(
                request, response);
        }
       ....

    } catch (IOException e) {
        // Ignore
    } finally {
       ...
    }
}
```

注释写的还可以，继续看一下此解析把：

> org.apache.catalina.connector.CoyoteAdapter#postParseRequest

```java
protected boolean postParseRequest(org.apache.coyote.Request req, Request request,
                                   org.apache.coyote.Response res, Response response) throws IOException, ServletException {

    // If the processor has set the scheme (AJP does this, HTTP does this if
    // SSL is enabled) use this to set the secure flag as well. If the
    // processor hasn't set it, use the settings from the connector
    if (req.scheme().isNull()) {
        // Use connector scheme and secure configuration, (defaults to
        // "http" and false respectively)
        /**
             * 1. 解析schema
             */
        req.scheme().setString(connector.getScheme());
        request.setSecure(connector.getSecure());
    } else {
        // Use processor specified scheme to determine secure state
        request.setSecure(req.scheme().equals("https"));
    }

    // At this point the Host header has been processed.
    // Override if the proxyPort/proxyHost are set
    /**
         *  2. 解析代理
         */
    String proxyName = connector.getProxyName();
    int proxyPort = connector.getProxyPort();
    if (proxyPort != 0) {
        req.setServerPort(proxyPort);
    } else if (req.getServerPort() == -1) {
        // Not explicitly set. Use default ports based on the scheme
        if (req.scheme().equals("https")) {
            req.setServerPort(443);
        } else {
            req.setServerPort(80);
        }
    }
    if (proxyName != null) {
        req.serverName().setString(proxyName);
    }
    // uri  如: /patcher/dis
    /**
         * 3. 解析uri
         */
    MessageBytes undecodedURI = req.requestURI();

    // Check for ping OPTIONS * request
    if (undecodedURI.equals("*")) {
        if (req.method().equalsIgnoreCase("OPTIONS")) {
            StringBuilder allow = new StringBuilder();
            allow.append("GET, HEAD, POST, PUT, DELETE, OPTIONS");
            // Trace if allowed
            if (connector.getAllowTrace()) {
                allow.append(", TRACE");
            }
            res.setHeader("Allow", allow.toString());
            // Access log entry as processing won't reach AccessLogValve
            connector.getService().getContainer().logAccess(request, response, 0, true);
            return false;
        } else {
            response.sendError(400, "Invalid URI");
        }
    }

    MessageBytes decodedURI = req.decodedURI();

    if (undecodedURI.getType() == MessageBytes.T_BYTES) {
        // Copy the raw URI to the decodedURI
        decodedURI.duplicate(undecodedURI);

        // Parse the path parameters. This will:
        //   - strip out the path parameters
        //   - convert the decodedURI to bytes
        /**
             * 4. 解析 请求中参数--path parameter
             */
        parsePathParameters(req, request);

        // URI decoding
        // %xx decoding of the URL
        try {
            req.getURLDecoder().convert(decodedURI, false);
        } catch (IOException ioe) {
            response.sendError(400, "Invalid URI: " + ioe.getMessage());
        }
        // Normalization
        if (normalize(req.decodedURI())) {
            // Character decoding
            convertURI(decodedURI, request);
            // Check that the URI is still normalized
            if (!checkNormalize(req.decodedURI())) {
                response.sendError(400, "Invalid URI");
            }
        } else {
            response.sendError(400, "Invalid URI");
        }
    } else {
        /* The URI is chars or String, and has been sent using an in-memory
             * protocol handler. The following assumptions are made:
             * - req.requestURI() has been set to the 'original' non-decoded,
             *   non-normalized URI
             * - req.decodedURI() has been set to the decoded, normalized form
             *   of req.requestURI()
             */
        decodedURI.toChars();
        // Remove all path parameters; any needed path parameter should be set
        // using the request object rather than passing it in the URL
        CharChunk uriCC = decodedURI.getCharChunk();
        int semicolon = uriCC.indexOf(';');
        if (semicolon > 0) {
            decodedURI.setChars(uriCC.getBuffer(), uriCC.getStart(), semicolon);
        }
    }
    // Request mapping.
    MessageBytes serverName;
    if (connector.getUseIPVHosts()) {
        serverName = req.localName();
        if (serverName.isNull()) {
            // well, they did ask for it
            res.action(ActionCode.REQ_LOCAL_NAME_ATTRIBUTE, null);
        }
    } else {
        // servername localhost
        /**
             *  5. 获取此请求的host
             */
        serverName = req.serverName();
    }
    // Version for the second mapping loop and
    // Context that we expect to get for that version
    String version = null;
    Context versionContext = null;
    boolean mapRequired = true;

    if (response.isError()) {
        // An error this early means the URI is invalid. Ensure invalid data
        // is not passed to the mapper. Note we still want the mapper to
        // find the correct host.
        decodedURI.recycle();
    }
    while (mapRequired) {
        // This will map the the latest version by default
        // todo 此处会针对uri 解析对应的host context 以及 servlet
        /**
             *  6. 解析此请求对应的host  context  以及servlet
             */
        connector.getService().getMapper().map(serverName, decodedURI,
                                               version, request.getMappingData());
        // If there is no context at this point, either this is a 404
        // because no ROOT context has been deployed or the URI was invalid
        // so no context could be mapped.
        if (request.getContext() == null) {
            // Don't overwrite an existing error
            if (!response.isError()) {
                response.sendError(404, "Not found");
            }
            // Allow processing to continue.
            // If present, the error reporting valve will provide a response
            // body.
            return true;
        }

        // Now we have the context, we can parse the session ID from the URL
        // (if any). Need to do this before we redirect in case we need to
        // include the session id in the redirect
        /**
             * 解析sessionID
             */
        String sessionID;
        if (request.getServletContext().getEffectiveSessionTrackingModes()
            .contains(SessionTrackingMode.URL)) {

            // Get the session ID if there was one
            sessionID = request.getPathParameter(
                SessionConfig.getSessionUriParamName(
                    request.getContext()));
            if (sessionID != null) {
                request.setRequestedSessionId(sessionID);
                request.setRequestedSessionURL(true);
            }
        }

        // Look for session ID in cookies and SSL session
        /**
             *  解析sessionID 以及 cookies
             */
        parseSessionCookiesId(request);
        parseSessionSslId(request);

        sessionID = request.getRequestedSessionId();

        mapRequired = false;
        if (version != null && request.getContext() == versionContext) {
            // We got the version that we asked for. That is it.
        } else {
            version = null;
            versionContext = null;

            Context[] contexts = request.getMappingData().contexts;
            // Single contextVersion means no need to remap
            // No session ID means no possibility of remap
            if (contexts != null && sessionID != null) {
                // Find the context associated with the session
                for (int i = contexts.length; i > 0; i--) {
                    Context ctxt = contexts[i - 1];
                    if (ctxt.getManager().findSession(sessionID) != null) {
                        // We found a context. Is it the one that has
                        // already been mapped?
                        if (!ctxt.equals(request.getMappingData().context)) {
                            // Set version so second time through mapping
                            // the correct context is found
                            version = ctxt.getWebappVersion();
                            versionContext = ctxt;
                            // Reset mapping
                            request.getMappingData().recycle();
                            mapRequired = true;
                            // Recycle cookies and session info in case the
                            // correct context is configured with different
                            // settings
                            request.recycleSessionInfo();
                            request.recycleCookieInfo(true);
                        }
                        break;
                    }
                }
            }
        }
        if (!mapRequired && request.getContext().getPaused()) {
            // Found a matching context but it is paused. Mapping data will
            // be wrong since some Wrappers may not be registered at this
            // point.
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                // Should never happen
            }
            // Reset mapping
            request.getMappingData().recycle();
            mapRequired = true;
        }
    }
    // Possible redirect
    MessageBytes redirectPathMB = request.getMappingData().redirectPath;
    if (!redirectPathMB.isNull()) {
        String redirectPath = URLEncoder.DEFAULT.encode(
            redirectPathMB.toString(), StandardCharsets.UTF_8);
        String query = request.getQueryString();
        if (request.isRequestedSessionIdFromURL()) {
            // This is not optimal, but as this is not very common, it
            // shouldn't matter
            redirectPath = redirectPath + ";" +
                SessionConfig.getSessionUriParamName(
                request.getContext()) +
                "=" + request.getRequestedSessionId();
        }
        if (query != null) {
            // This is not optimal, but as this is not very common, it
            // shouldn't matter
            redirectPath = redirectPath + "?" + query;
        }
        response.sendRedirect(redirectPath);
        request.getContext().logAccess(request, response, 0, true);
        return false;
    }

    // Filter trace method
    if (!connector.getAllowTrace()
        && req.method().equalsIgnoreCase("TRACE")) {
        Wrapper wrapper = request.getWrapper();
        String header = null;
        if (wrapper != null) {
            String[] methods = wrapper.getServletMethods();
            if (methods != null) {
                for (int i=0; i < methods.length; i++) {
                    if ("TRACE".equals(methods[i])) {
                        continue;
                    }
                    if (header == null) {
                        header = methods[i];
                    } else {
                        header += ", " + methods[i];
                    }
                }
            }
        }
        res.setStatus(405);
        if (header != null) {
            res.addHeader("Allow", header);
        }
        res.setMessage("TRACE method is not allowed");
        request.getContext().logAccess(request, response, 0, true);
        return false;
    }
    // 用户认证
    doConnectorAuthenticationAuthorization(req, request);
    return true;
}
```

此解析篇幅也比较长，当然也是做了很多的工作，主要解析：

1. 解析schema
2. 解析代理
3. 解析uri
4. 解析请求参数中 path parameter
5. 获取此请求中的host
6. 解析此请求对应的host，context以及servlet
7. 解析sessionID
8. 解析sessionID以及cookies
9. 用户认证

其他解析就不多做解释了，这里看一下此第六步：

```java
/***  6. 解析此请求对应的host  context  以及servlet */
connector.getService().getMapper().map(serverName, decodedURI,version, request.getMappingData());
```

说到此解析，就要回顾一下之前解析到的一个监听器，mapperListener；在此mapperListener中当时把所有的host，context以及servlet和其映射全部记录到了一个mapper中，此mapper是service中的一个属性，那在此处就使用使用此mapper来对所对应的host，context，servlet的解析。

> org.apache.catalina.mapper.Mapper#map(org.apache.tomcat.util.buf.MessageBytes, org.apache.tomcat.util.buf.MessageBytes, java.lang.String, org.apache.catalina.mapper.MappingData)

```java
// 解析host  context  servlet 根据 uri
// mappingData 记录具体的映射关系
public void map(MessageBytes host, MessageBytes uri, String version,
                MappingData mappingData) throws IOException {

    if (host.isNull()) {
        host.getCharChunk().append(defaultHostName);
    }
    host.toChars();
    uri.toChars();
    /**
         *  具体的解析动作
         */
    internalMap(host.getCharChunk(), uri.getCharChunk(), version,
                mappingData);
}
```

host和context的解析动作：

> org.apache.catalina.mapper.Mapper#internalMap

```java
private final void internalMap(CharChunk host, CharChunk uri,
                               String version, MappingData mappingData) throws IOException {

    if (mappingData.host != null) {
        throw new AssertionError();
    }
    // Virtual host mapping
    /**
         *  1. 解析host
         */
    MappedHost[] hosts = this.hosts;
    // exactFindIgnoreCase 查找匹配时, 根据host的名字匹配
    MappedHost mappedHost = exactFindIgnoreCase(hosts, host);
    if (mappedHost == null) {
        // Note: Internally, the Mapper does not use the leading * on a
        //       wildcard host. This is to allow this shortcut.
        int firstDot = host.indexOf('.');
        if (firstDot > -1) {
            int offset = host.getOffset();
            try {
                host.setOffset(firstDot + offset);
                mappedHost = exactFindIgnoreCase(hosts, host);
            } finally {
                // Make absolutely sure this gets reset
                host.setOffset(offset);
            }
        }
        if (mappedHost == null) {
            mappedHost = defaultHost;
            if (mappedHost == null) {
                return;
            }
        }
    }
    // 记录匹配到的host
    mappingData.host = mappedHost.object;
    if (uri.isNull()) {
        // Can't map context or wrapper without a uri
        return;
    }
    uri.setLimit(-1);
    /**
         * 2. 解析context
         * 根据 uri 如何 context的name去进行匹配,一般情况 context的name就是其path
         */
    ContextList contextList = mappedHost.contextList;
    MappedContext[] contexts = contextList.contexts;
    int pos = find(contexts, uri);
    if (pos == -1) {
        return;
    }
    int lastSlash = -1;
    int uriEnd = uri.getEnd();
    int length = -1;
    boolean found = false;
    MappedContext context = null;
    while (pos >= 0) {
        context = contexts[pos];
        if (uri.startsWith(context.name)) {
            length = context.name.length();
            if (uri.getLength() == length) {
                found = true;
                break;
            } else if (uri.startsWithIgnoreCase("/", length)) {
                found = true;
                break;
            }
        }
        if (lastSlash == -1) {
            lastSlash = nthSlash(uri, contextList.nesting + 1);
        } else {
            lastSlash = lastSlash(uri);
        }
        uri.setEnd(lastSlash);
        pos = find(contexts, uri);
    }
    uri.setEnd(uriEnd);
    if (!found) {
        if (contexts[0].name.equals("")) {
            context = contexts[0];
        } else {
            context = null;
        }
    }
    if (context == null) {
        return;
    }
    // 记录匹配到的context的path
    mappingData.contextPath.setString(context.name);
    ContextVersion contextVersion = null;
    ContextVersion[] contextVersions = context.versions;
    final int versionCount = contextVersions.length;
    if (versionCount > 1) {
        Context[] contextObjects = new Context[contextVersions.length];
        for (int i = 0; i < contextObjects.length; i++) {
            contextObjects[i] = contextVersions[i].object;
        }
        // 记录匹配到的context
        mappingData.contexts = contextObjects;
        if (version != null) {
            contextVersion = exactFind(contextVersions, version);
        }
    }
    if (contextVersion == null) {
        // Return the latest version
        // The versions array is known to contain at least one element
        contextVersion = contextVersions[versionCount - 1];
    }
    mappingData.context = contextVersion.object;
    mappingData.contextSlashCount = contextVersion.slashCount;
    // Wrapper mapping
    /**
         * 3. 根据uri去解析 mapping
         */
    if (!contextVersion.isPaused()) {
        // 具体解析mapping
        internalMapWrapper(contextVersion, uri, mappingData);
    }
}
```

解析mapper的映射关系：

> org.apache.catalina.mapper.Mapper#internalMapWrapper

```java
private final void internalMapWrapper(ContextVersion contextVersion,
                                      CharChunk path,
                                      MappingData mappingData) throws IOException {

    int pathOffset = path.getOffset();
    int pathEnd = path.getEnd();
    boolean noServletPath = false;

    int length = contextVersion.path.length();
    if (length == (pathEnd - pathOffset)) {
        noServletPath = true;
    }
    int servletPath = pathOffset + length;
    path.setOffset(servletPath);

    // Rule 1 -- Exact Match
    // 规则1: 精确匹配
    MappedWrapper[] exactWrappers = contextVersion.exactWrappers;
    // 具体的匹配动作
    internalMapExactWrapper(exactWrappers, path, mappingData);

    // Rule 2 -- Prefix Match
    // 规则2: 前缀匹配
    boolean checkJspWelcomeFiles = false;
    MappedWrapper[] wildcardWrappers = contextVersion.wildcardWrappers;
    if (mappingData.wrapper == null) {
        internalMapWildcardWrapper(wildcardWrappers, contextVersion.nesting,
                                   path, mappingData);
        if (mappingData.wrapper != null && mappingData.jspWildCard) {
            char[] buf = path.getBuffer();
            if (buf[pathEnd - 1] == '/') {
                /*
                     * Path ending in '/' was mapped to JSP servlet based on
                     * wildcard match (e.g., as specified in url-pattern of a
                     * jsp-property-group.
                     * Force the context's welcome files, which are interpreted
                     * as JSP files (since they match the url-pattern), to be
                     * considered. See Bugzilla 27664.
                     */
                mappingData.wrapper = null;
                checkJspWelcomeFiles = true;
            } else {
                // See Bugzilla 27704
                mappingData.wrapperPath.setChars(buf, path.getStart(),
                                                 path.getLength());
                mappingData.pathInfo.recycle();
            }
        }
    }
    if(mappingData.wrapper == null && noServletPath &&
       contextVersion.object.getMapperContextRootRedirectEnabled()) {
        // The path is empty, redirect to "/"
        path.append('/');
        pathEnd = path.getEnd();
        mappingData.redirectPath.setChars
            (path.getBuffer(), pathOffset, pathEnd - pathOffset);
        path.setEnd(pathEnd - 1);
        return;
    }

    // Rule 3 -- Extension Match
    // 规则3: 扩展匹配
    MappedWrapper[] extensionWrappers = contextVersion.extensionWrappers;
    if (mappingData.wrapper == null && !checkJspWelcomeFiles) {
        internalMapExtensionWrapper(extensionWrappers, path, mappingData,
                                    true);
    }
    // Rule 4 -- Welcome resources processing for servlets
    if (mappingData.wrapper == null) {
        boolean checkWelcomeFiles = checkJspWelcomeFiles;
        if (!checkWelcomeFiles) {
            char[] buf = path.getBuffer();
            checkWelcomeFiles = (buf[pathEnd - 1] == '/');
        }
        if (checkWelcomeFiles) {
            for (int i = 0; (i < contextVersion.welcomeResources.length)
                 && (mappingData.wrapper == null); i++) {
                path.setOffset(pathOffset);
                path.setEnd(pathEnd);
                path.append(contextVersion.welcomeResources[i], 0,
                            contextVersion.welcomeResources[i].length());
                path.setOffset(servletPath);

                // Rule 4a -- Welcome resources processing for exact macth
                internalMapExactWrapper(exactWrappers, path, mappingData);

                // Rule 4b -- Welcome resources processing for prefix match
                if (mappingData.wrapper == null) {
                    internalMapWildcardWrapper
                        (wildcardWrappers, contextVersion.nesting,
                         path, mappingData);
                }

                // Rule 4c -- Welcome resources processing
                //            for physical folder
                if (mappingData.wrapper == null
                    && contextVersion.resources != null) {
                    String pathStr = path.toString();
                    WebResource file =
                        contextVersion.resources.getResource(pathStr);
                    if (file != null && file.isFile()) {
                        internalMapExtensionWrapper(extensionWrappers, path,
                                                    mappingData, true);
                        if (mappingData.wrapper == null
                            && contextVersion.defaultWrapper != null) {
                            mappingData.wrapper =
                                contextVersion.defaultWrapper.object;
                            mappingData.requestPath.setChars
                                (path.getBuffer(), path.getStart(),
                                 path.getLength());
                            mappingData.wrapperPath.setChars
                                (path.getBuffer(), path.getStart(),
                                 path.getLength());
                            mappingData.requestPath.setString(pathStr);
                            mappingData.wrapperPath.setString(pathStr);
                        }
                    }
                }
            }
            path.setOffset(servletPath);
            path.setEnd(pathEnd);
        }
    }
    /* welcome file processing - take 2
         * Now that we have looked for welcome files with a physical
         * backing, now look for an extension mapping listed
         * but may not have a physical backing to it. This is for
         * the case of index.jsf, index.do, etc.
         * A watered down version of rule 4
         */
    if (mappingData.wrapper == null) {
        boolean checkWelcomeFiles = checkJspWelcomeFiles;
        if (!checkWelcomeFiles) {
            char[] buf = path.getBuffer();
            checkWelcomeFiles = (buf[pathEnd - 1] == '/');
        }
        if (checkWelcomeFiles) {
            for (int i = 0; (i < contextVersion.welcomeResources.length)
                 && (mappingData.wrapper == null); i++) {
                path.setOffset(pathOffset);
                path.setEnd(pathEnd);
                path.append(contextVersion.welcomeResources[i], 0,
                            contextVersion.welcomeResources[i].length());
                path.setOffset(servletPath);
                internalMapExtensionWrapper(extensionWrappers, path,
                                            mappingData, false);
            }
            path.setOffset(servletPath);
            path.setEnd(pathEnd);
        }
    }
    // Rule 7 -- Default servlet
    if (mappingData.wrapper == null && !checkJspWelcomeFiles) {
        if (contextVersion.defaultWrapper != null) {
            mappingData.wrapper = contextVersion.defaultWrapper.object;
            mappingData.requestPath.setChars
                (path.getBuffer(), path.getStart(), path.getLength());
            mappingData.wrapperPath.setChars
                (path.getBuffer(), path.getStart(), path.getLength());
            mappingData.matchType = MappingMatch.DEFAULT;
        }
        // Redirection to a folder
        char[] buf = path.getBuffer();
        if (contextVersion.resources != null && buf[pathEnd -1 ] != '/') {
            String pathStr = path.toString();
            // Note: Check redirect first to save unnecessary getResource()
            //       call. See BZ 62968.
            if (contextVersion.object.getMapperDirectoryRedirectEnabled()) {
                WebResource file;
                // Handle context root
                if (pathStr.length() == 0) {
                    file = contextVersion.resources.getResource("/");
                } else {
                    file = contextVersion.resources.getResource(pathStr);
                }
                if (file != null && file.isDirectory()) {
                    // Note: this mutates the path: do not do any processing
                    // after this (since we set the redirectPath, there
                    // shouldn't be any)
                    path.setOffset(pathOffset);
                    path.append('/');
                    mappingData.redirectPath.setChars
                        (path.getBuffer(), path.getStart(), path.getLength());
                } else {
                    mappingData.requestPath.setString(pathStr);
                    mappingData.wrapperPath.setString(pathStr);
                }
            } else {
                mappingData.requestPath.setString(pathStr);
                mappingData.wrapperPath.setString(pathStr);
            }
        }
    }
    path.setOffset(pathOffset);
    path.setEnd(pathEnd);
}
```

到此，此请求对应的host，context，servlet都解析完成了，并存储到request中request.getMappingData(） 中。

所以了，为啥那个请求在后面容器中可以直接获取映射的host，context，servlet就比较清晰了。









































































































