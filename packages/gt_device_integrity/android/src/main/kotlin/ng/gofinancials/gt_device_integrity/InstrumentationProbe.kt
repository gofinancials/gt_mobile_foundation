package ng.gofinancials.gt_device_integrity

import android.os.Debug
import java.io.File
import java.net.InetSocketAddress
import java.net.Socket

/** What [InstrumentationProbe] found. Each evidence entry says what raised its reading. */
internal data class InstrumentationReadings(
    val frida: Boolean,
    val hookingFramework: Boolean,
    val debuggerAttached: Boolean,
    val evidence: List<String>,
)

/**
 * Looks for Frida, hooking frameworks and an attached debugger from inside the
 * process. Like every in-process check it can itself be hooked; it raises the
 * cost of an attack rather than ruling one out.
 *
 * Opens a socket to 127.0.0.1, so it must not run on the main thread.
 */
internal class InstrumentationProbe {
    fun read(): InstrumentationReadings {
        val maps = readLines("/proc/self/maps")
        val fridaEvidence = mapsEvidence(maps, FRIDA_LIBRARIES) + threadEvidence() + portEvidence()
        val hookingEvidence = mapsEvidence(maps, HOOKING_LIBRARIES) + xposedEvidence()
        val debuggerEvidence = debuggerEvidence()
        val evidence = fridaEvidence + hookingEvidence + debuggerEvidence

        return InstrumentationReadings(
            frida = fridaEvidence.isNotEmpty(),
            hookingFramework = hookingEvidence.isNotEmpty(),
            debuggerAttached = debuggerEvidence.isNotEmpty(),
            evidence = evidence,
        )
    }

    private fun mapsEvidence(maps: List<String>, markers: List<String>): List<String> {
        val found = markers.filter { marker -> maps.any { it.contains(marker, ignoreCase = true) } }

        return found.map { "maps:$it" }
    }

    private fun threadEvidence(): List<String> {
        val tasks = File("/proc/self/task").listFiles().orEmpty()
        val names = tasks.mapNotNull { readText(File(it, "comm"))?.trim() }.toSet()
        val found = FRIDA_THREADS.filter { it in names }

        return found.map { "thread:$it" }
    }

    private fun portEvidence(): List<String> {
        if (!isListening(FRIDA_PORT)) return emptyList()

        return listOf("port:$FRIDA_PORT")
    }

    private fun xposedEvidence(): List<String> {
        val frames = Throwable().stackTrace.map { it.className }
        val isOnStack = frames.any { frame -> XPOSED_CLASSES.any { frame.contains(it) } }
        val evidence = mutableListOf<String>()

        if (isOnStack) evidence += "stack:xposed"
        if (isXposedBridgeLoadable()) evidence += "class:XposedBridge"

        return evidence
    }

    private fun debuggerEvidence(): List<String> {
        val evidence = mutableListOf<String>()
        val tracerLine = readLines("/proc/self/status").firstOrNull { it.startsWith("TracerPid:") }
        val tracerPid = tracerLine?.substringAfter(":")?.trim()?.toIntOrNull() ?: 0

        if (Debug.isDebuggerConnected()) evidence += "debugger:jdwp"
        if (tracerPid != 0) evidence += "debugger:tracer_pid"

        return evidence
    }

    private fun isXposedBridgeLoadable(): Boolean {
        return try {
            ClassLoader.getSystemClassLoader().loadClass(XPOSED_BRIDGE)
            true
        } catch (_: Throwable) {
            false
        }
    }

    /** Needs the INTERNET permission, which every app using this has; without it the probe answers no. */
    private fun isListening(port: Int): Boolean {
        return try {
            val address = InetSocketAddress("127.0.0.1", port)
            Socket().use { it.connect(address, PORT_TIMEOUT_MS) }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun readLines(path: String): List<String> {
        return try {
            File(path).readLines()
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun readText(file: File): String? {
        return try {
            file.readText()
        } catch (_: Exception) {
            null
        }
    }

    private companion object {
        /** frida-server's default port, and Frida Gadget's in its default listen mode. */
        const val FRIDA_PORT = 27042
        const val PORT_TIMEOUT_MS = 200
        const val XPOSED_BRIDGE = "de.robv.android.xposed.XposedBridge"

        val FRIDA_LIBRARIES = listOf("frida", "gum-js-loop")
        val HOOKING_LIBRARIES = listOf("xposed", "edxp", "lspd", "lspatch", "libsubstrate")
        val XPOSED_CLASSES = listOf("de.robv.android.xposed", "org.lsposed", "LSPHooker")

        /**
         * Thread names Frida's agent starts. Its GLib threads (gmain, gdbus) are left
         * out: any app shipping a GLib-linked library has them too.
         */
        val FRIDA_THREADS = listOf("gum-js-loop", "pool-frida", "linjector")
    }
}
