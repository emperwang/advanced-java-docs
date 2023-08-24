

```properties
# 定位内存泄漏时的一个jvm参数
添加-XX:NativeMemoryTracking=detailJVM参数重启项目，使用命令jcmd pid VM.native_memory detail 查看进程的内存分布

# VM.native_memory的一个使用
$  jcmd 6282 help VM.native_memory
6282:
VM.native_memory
Print native memory usage

Impact: Medium

Permission: java.lang.management.ManagementPermission(monitor)

Syntax : VM.native_memory [options]

Options: (options must be specified using the <key> or <key>=<value> syntax)
        summary : [optional] request runtime to report current memory summary, which includes total reserved and committed memory, along with memory usage summary by each subsytem. (BOOLEAN, false)
        detail : [optional] request runtime to report memory allocation >= 1K by each callsite. (BOOLEAN, false)
        baseline : [optional] request runtime to baseline current memory usage, so it can be compared against in later time. (BOOLEAN, false)
        summary.diff : [optional] request runtime to report memory summary comparison against previous baseline. (BOOLEAN, false)
        detail.diff : [optional] request runtime to report memory detail comparison against previous baseline, which shows the memory allocation activities at different callsites. (BOOLEAN, false)
        shutdown : [optional] request runtime to shutdown itself and free the memory used by runtime. (BOOLEAN, false)
        statistics : [optional] print tracker statistics for tuning purpose. (BOOLEAN, false)
        scale : [optional] Memory usage in which scale, KB, MB or GB (STRING, KB)
```

```properties
# 使用语法
jcmd <process id/main class> command 
# 查看jcmd 对当前 JVM 可发送的command:
# jcmd  pid help
$ jcmd 6282 help
6282:
The following commands are available:
JFR.stop
JFR.start
JFR.dump
JFR.check
VM.native_memory
VM.check_commercial_features
VM.unlock_commercial_features
ManagementAgent.stop
ManagementAgent.start_local
ManagementAgent.start
VM.classloader_stats
GC.rotate_log
Thread.print
GC.class_stats
GC.class_histogram
GC.heap_dump
GC.finalizer_info
GC.heap_info
GC.run_finalization
GC.run
VM.uptime
VM.dynlibs
VM.flags
VM.system_properties
VM.command_line
VM.version
help
For more information about a specific command use 'help <command>'.

# 查看对应命令的帮助
$ jcmd 6282 help GC.run
6282:
GC.run
Call java.lang.System.gc().
Impact: Medium: Depends on Java heap size and content.
Syntax: GC.run

```

