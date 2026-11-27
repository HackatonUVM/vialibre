package mx.vialibre.vialibre

import android.content.pm.PackageManager
import android.os.Bundle
import com.google.android.gms.maps.MapsApiSettings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            // Atribución de uso requerida por Google Maps Platform
            MapsApiSettings.addInternalUsageAttributionId(
                applicationContext,
                "gmp_git_agentskills_v1"
            )
        } catch (e: Throwable) {
            // No bloquear el inicio de la app si Play Services o Maps no están presentes
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mx.vialibre/config"
        ).setMethodCallHandler { call, result ->
            if (call.method == "hasMapsApiKey") {
                val appInfo = packageManager.getApplicationInfo(
                    packageName,
                    PackageManager.GET_META_DATA
                )
                val key = appInfo.metaData
                    ?.getString("com.google.android.geo.API_KEY")
                    ?.trim()
                result.success(!key.isNullOrEmpty())
            } else {
                result.notImplemented()
            }
        }
    }
}
