# Maven Assembly

```shell
The Assembly Plugin for Maven is primarily intended to allow users to aggregate the project output along with its dependencies, modules, site documentation, and other files into a single distributable archive.

大意:assembly 插件主要功能是允许用户把项目中的依赖，modules，site 文档，和其他文件打包成一个发布archive，来进行发布。
```

Assembly打包时，需要根据一个xml文件来指定具体需要打包什么文件。xml文件元素意思如下：

官网Assembly.xml参考:

```shell
http://maven.apache.org/plugins/maven-assembly-plugin/assembly.html
```

Assembly文件编写元素:

```xml
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
      <id/>    #  指定一个id
      <formats/>	# 最后打包的格式 tar  zip  dir
      <includeBaseDirectory/>  # 打包时，是不是添加一个基本目录
      <baseDirectory/>		# 指定基本目录的名字,默认时finalName
      <includeSiteDirectory/>	# 是否包含site目录
      <containerDescriptorHandlers> # 此具有对文件合并的功能 
        <containerDescriptorHandler>
          <handlerName/>
          <configuration/>
        </containerDescriptorHandler>
      </containerDescriptorHandlers> 
      <moduleSets>    # 在多模块project下，包含那些模块
        <moduleSet>
          <useAllReactorProjects/>
          <includeSubModules/>
          <includes/>
          <excludes/>
          <sources>  # 包含源码
            <useDefaultExcludes/>
            <outputDirectory/>
            <includes/>
            <excludes/>
            <fileMode/>
            <directoryMode/>
            <fileSets>	# 包含的文件
              <fileSet>
                <useDefaultExcludes/>
                <outputDirectory/>
                <includes/>
                <excludes/>
                <fileMode/>
                <directoryMode/>
                <directory/>
                <lineEnding/>
                <filtered/>
              </fileSet>
            </fileSets>
            <includeModuleDirectory/>
            <excludeSubModuleDirectories/>
            <outputDirectoryMapping/>
          </sources>
          <binaries>  # 包含二进制
            <outputDirectory/>
            <includes/>
            <excludes/>
            <fileMode/>
            <directoryMode/>
            <attachmentClassifier/>
            <includeDependencies/>
            <dependencySets>
              <dependencySet>
                <outputDirectory/>
                <includes/>
                <excludes/>
                <fileMode/>
                <directoryMode/>
                <useStrictFiltering/>
                <outputFileNameMapping/>
                <unpack/>
                <unpackOptions>
                  <includes/>
                  <excludes/>
                  <filtered/>
                  <lineEnding/>
                  <useDefaultExcludes/>
                  <encoding/>
                </unpackOptions>
                <scope/>
                <useProjectArtifact/>
                <useProjectAttachments/>
                <useTransitiveDependencies/>
                <useTransitiveFiltering/>
              </dependencySet>
            </dependencySets>
            <unpack/>
            <unpackOptions>
              <includes/>
              <excludes/>
              <filtered/>
              <lineEnding/>
              <useDefaultExcludes/>
              <encoding/>
            </unpackOptions>
            <outputFileNameMapping/>
          </binaries>
        </moduleSet>
      </moduleSets>
      <fileSets>   # 包含的文件,此可以使用正则表达式,指定某一类文件
        <fileSet>
          <useDefaultExcludes/>
          <outputDirectory/>
          <includes/>
          <excludes/>
          <fileMode/>
          <directoryMode/>
          <directory/>
          <lineEnding/>
          <filtered/>
        </fileSet>
      </fileSets>
      <files>		# 指定单个文件
        <file>
          <source/>
          <outputDirectory/>
          <destName/>
          <fileMode/>
          <lineEnding/>
          <filtered/>
        </file>
      </files>
      <dependencySets>	# 指定依赖
        <dependencySet>
          <outputDirectory/>
          <includes/>
          <excludes/>
          <fileMode/>
          <directoryMode/>
          <useStrictFiltering/>
          <outputFileNameMapping/>
          <unpack/>
          <unpackOptions>
            <includes/>
            <excludes/>
            <filtered/>
            <lineEnding/>
            <useDefaultExcludes/>
            <encoding/>
          </unpackOptions>
          <scope/>
          <useProjectArtifact/>
          <useProjectAttachments/>
          <useTransitiveDependencies/>
          <useTransitiveFiltering/>
        </dependencySet>
      </dependencySets>
      <repositories>	# 打包一个respostory到包中
        <repository>
          <outputDirectory/>
          <includes/>
          <excludes/>
          <fileMode/>
          <directoryMode/>
          <includeMetadata/>
          <groupVersionAlignments>
            <groupVersionAlignment>
              <id/>
              <version/>
              <excludes/>
            </groupVersionAlignment>
          </groupVersionAlignments>
          <scope/>
        </repository>
      </repositories>
      <componentDescriptors/>
    </assembly>
```

具体可以查看官网.