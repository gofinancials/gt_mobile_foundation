package ng.gofinancials.gt_device_integrity

import android.app.ActivityManager
import android.app.Application
import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * Reads what the device says about itself. Every entry is a measurement;
 * deciding which ones block the app belongs to gt_mobile_foundation.
 *
 * The checks are NewMobileChannel's SecurityPlugin, with one difference: NMC
 * folds root into its clone result, and this reports the two separately.
 */
class GtDeviceIntegrityPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "gt_device_integrity")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "report" -> result.success(report())
            else -> result.notImplemented()
        }
    }

    private fun report(): Map<String, Any?> = mapOf(
        "platform" to "android",
        "packageName" to context.packageName,
        "rooted" to isRooted(),
        "emulator" to isEmulator(),
        "cloneEnvironment" to isCloneEnvironment(),
        "processNameMismatch" to isProcessNameMismatch(),
        "testKeys" to hasTestKeys(),
        "developerMode" to isDeveloperModeEnabled(),
        "installer" to installerPackageName(),
        "signature" to signatureSha256(),
    )

    private fun hasTestKeys(): Boolean = Build.TAGS?.contains("test-keys") == true

    private fun isRooted(): Boolean {
        val suPaths = listOf(
            "/system/app/Superuser.apk",
            "/system/bin/su",
            "/system/xbin/su",
            "/system/sbin/su",
            "/system/bin/failsafe/su",
            "/sbin/su",
            "/su/bin/su",
            "/vendor/bin/su",
            "/data/local/su",
            "/data/local/bin/su",
            "/data/local/xbin/su",
        )
        if (hasTestKeys()) return true
        if (suPaths.any { File(it).exists() }) return true
        val pathDirs = System.getenv("PATH")?.split(":").orEmpty()
        if (pathDirs.any { File(it, "su").exists() }) return true
        return isPackageInstalled("com.topjohnwu.magisk")
    }

    private fun isCloneEnvironment(): Boolean {
        val path = context.filesDir.path.lowercase()
        val markers = listOf("parallel", "dual", "clone", "virtual", "multiple", "island")
        if (markers.any { path.contains(it) }) return true

        // /data/user/<id>/<package>/files has five segments; a cloning app
        // nests the sandbox deeper.
        val segments = context.filesDir.path.split("/").filter { it.isNotEmpty() }
        if (segments.size > 6) return true
        if (isProcessNameMismatch()) return true

        val cloneApps = listOf(
            "com.parallel.space.lite",
            "com.lbe.parallel.intl",
            "com.lbe.parallel",
            "com.cloneapp.cloner",
            "com.dualspace.pro",
            "io.virtualapp",
            "com.excelliance.multiaccounts",
        )
        return cloneApps.any { isPackageInstalled(it) }
    }

    private fun isProcessNameMismatch(): Boolean {
        val name = currentProcessName() ?: return false
        return !name.equals(context.packageName, ignoreCase = true)
    }

    private fun isEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.orEmpty()
        val model = Build.MODEL.orEmpty()
        val hardware = Build.HARDWARE.orEmpty()
        val product = Build.PRODUCT.orEmpty()

        return fingerprint.startsWith("generic") ||
            fingerprint.contains("emulator") ||
            model.contains("google_sdk") ||
            model.contains("Emulator") ||
            model.contains("Android SDK built for") ||
            Build.MANUFACTURER.orEmpty().contains("Genymotion") ||
            hardware.contains("goldfish") ||
            hardware.contains("ranchu") ||
            hardware.contains("vbox86") ||
            product.startsWith("sdk_gphone") ||
            product in setOf("sdk", "google_sdk", "sdk_x86", "sdk_google", "vbox86p") ||
            hardware == "nox" ||
            (Build.BRAND.orEmpty().startsWith("generic") && Build.DEVICE.orEmpty().startsWith("generic"))
    }

    private fun isDeveloperModeEnabled(): Boolean {
        return try {
            Settings.Global.getInt(
                context.contentResolver,
                Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                0,
            ) == 1
        } catch (_: Exception) {
            false
        }
    }

    /** The store or tool that installed the app, or null when Android does not say. */
    private fun installerPackageName(): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.packageManager.getInstallSourceInfo(context.packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getInstallerPackageName(context.packageName)
            }
        } catch (_: Exception) {
            null
        }
    }

    /** SHA-256 of the first signing certificate, upper-case hex, or null when unreadable. */
    private fun signatureSha256(): String? {
        return try {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                    .signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageInfo(context.packageName, PackageManager.GET_SIGNATURES).signatures
            }
            if (signatures.isNullOrEmpty()) return null
            val digest = MessageDigest.getInstance("SHA-256").digest(signatures[0].toByteArray())
            digest.joinToString("") { "%02X".format(it) }
        } catch (_: Exception) {
            null
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageInfo(packageName, 0)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun packageInfo(packageName: String, flags: Int): PackageInfo {
        val manager = context.packageManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return manager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(flags.toLong()))
        }
        @Suppress("DEPRECATION")
        return manager.getPackageInfo(packageName, flags)
    }

    private fun currentProcessName(): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                Application.getProcessName()
            } else {
                val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                manager.runningAppProcesses?.find { it.pid == Process.myPid() }?.processName
            }
        } catch (_: Exception) {
            null
        }
    }
}
