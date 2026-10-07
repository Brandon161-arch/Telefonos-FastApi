package com.electrophone.store;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ProgressBar;

import com.chaquo.python.PyObject;
import com.chaquo.python.Python;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;

/**
 * Arranque de la app:
 *
 * 1. PyApplication (declarado en el manifest) inicializa Python al crear el proceso.
 * 2. Un hilo secundario llama a bootstrap.serve_forever(), que levanta Uvicorn
 *    con FastAPI escuchando en http://127.0.0.1:8000.
 * 3. Otro hilo espera a que el puerto responda y entonces el WebView carga la tienda.
 *
 * El servidor vive mientras viva el proceso de la app (es 100% local: no sale
 * del telefono).
 */
public class MainActivity extends Activity {

    private static final String TAG = "ElectroPhone";
    private static final String BASE_URL = "http://127.0.0.1:8000";
    private static final int PORT = 8000;
    private static final long STARTUP_TIMEOUT_MS = 60_000L;

    // Para no intentar arrancar dos veces si la Activity se recrea
    private static volatile boolean serverStarted = false;

    private WebView webView;
    private ProgressBar progressBar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        progressBar = findViewById(R.id.progress_bar);
        webView = findViewById(R.id.web_view);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        // Necesario: el carrito y la sesion de login usan localStorage
        settings.setDomStorageEnabled(true);
        // Toda la navegacion se queda dentro de la app (sin abrir el navegador)
        webView.setWebViewClient(new WebViewClient());

        startServerThread();
        waitForServerThenLoad();
    }

    private void startServerThread() {
        if (serverStarted) {
            return;
        }
        serverStarted = true;
        new Thread(() -> {
            try {
                PyObject bootstrap = Python.getInstance().getModule("bootstrap");
                bootstrap.callAttr("serve_forever");
                Log.w(TAG, "serve_forever() termino inesperadamente");
            } catch (Throwable t) {
                Log.e(TAG, "Error al iniciar el servidor FastAPI", t);
            }
        }, "fastapi-server").start();
    }

    private void waitForServerThenLoad() {
        new Thread(() -> {
            long deadline = System.currentTimeMillis() + STARTUP_TIMEOUT_MS;
            boolean ready = false;
            while (System.currentTimeMillis() < deadline) {
                if (isServerListening()) {
                    ready = true;
                    break;
                }
                try {
                    Thread.sleep(250L);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
            if (!ready) {
                Log.e(TAG, "El servidor no respondio en " + STARTUP_TIMEOUT_MS + " ms");
            }
            runOnUiThread(() -> {
                progressBar.setVisibility(View.GONE);
                webView.setVisibility(View.VISIBLE);
                webView.loadUrl(BASE_URL);
            });
        }, "server-waiter").start();
    }

    private boolean isServerListening() {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", PORT), 500);
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK && webView != null && webView.canGoBack()) {
            webView.goBack();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }
}
