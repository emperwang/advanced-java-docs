[TOC]

# springmvc annotaion

##  method arguments

| controller method argument                                   | description |
| ------------------------------------------------------------ | ----------- |
| WebRequest,NativeWebRequest                                  |             |
| Javax.servlet.servletRequest, javax.servlet.ServletResponse  |             |
| javax.servlet.http.HttpSession                               |             |
| javax.servlet.http.PushBuilder                               |             |
| java.security.principal                                      |             |
| HttpMethod                                                   |             |
| java.util.Local                                              |             |
| java.util.TimeZone + java.time.ZoneId                        |             |
| java.io.InputStream, java.io.Reader                          |             |
| java.io.OutputStream,  java.io.Writer                        |             |
| @PathVariable                                                |             |
| @MatrixVariable                                              |             |
| @RequestParam                                                |             |
| @RequestHeader                                               |             |
| @Cookievalue                                                 |             |
| @RequestBody                                                 |             |
| @HttpEntity<B>                                               |             |
| @RequestPart                                                 |             |
| java.util.Map, org.springframework.ui.Model,  org.springframework.ui.ModelMap |             |
| RedirectAttributes                                           |             |
| @ModelAttribute                                              |             |
| Errors.,  BindingResult                                      |             |
| @SessionStatus + class-level,  @SessionAttributes            |             |
| @UriComponentbuilder                                         |             |
| @SessionAttribute                                            |             |
| @RequestAttribute                                            |             |





## return value

| controller method return value                               | Description |
| ------------------------------------------------------------ | ----------- |
| @ResponseBody                                                |             |
| HttpEntity<B>,  ResponseEntity<B>                            |             |
| HttpHeaders                                                  |             |
| String                                                       |             |
| View                                                         |             |
| java.util.Map,  org.springframework.ui.Model                 |             |
| @ModelAttribute                                              |             |
| @ModelAndView                                                |             |
| void                                                         |             |
| DeferredResult<V>                                            |             |
| Callable<V>                                                  |             |
| ListenableFuture<V>, java.util.concurrent.CompletionStage<V>,   java.util.concurrent.CompletableFuture<V> |             |
| ResponseBodyEmitter, SseEmitter                              |             |
| StreamingResponseBody                                        |             |
| ReactiveAdapterRegistry                                      |             |

