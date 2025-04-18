package com.example.fs_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.*
import androidx.core.app.NotificationCompat
import java.util.concurrent.TimeUnit

class NotificationService : Service() {
    private val CHANNEL_ID = "FitScaleReminder"
    private val NOTIFICATION_ID = 1
    private lateinit var notificationManager: NotificationManager
    private lateinit var handler: Handler
    private lateinit var inactivityRunnable: Runnable
    private val INACTIVITY_DELAY = TimeUnit.SECONDS.toMillis(30) // 30 seconds

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        setupInactivityTimer()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        resetInactivityTimer()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun setupInactivityTimer() {
        handler = Handler(Looper.getMainLooper())
        inactivityRunnable = Runnable {
            showNotification()
        }
    }

    private fun resetInactivityTimer() {
        handler.removeCallbacks(inactivityRunnable)
        handler.postDelayed(inactivityRunnable, INACTIVITY_DELAY)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "FitScale Reminder"
            val descriptionText = "Reminds you to return to FitScale"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification() {
        // Create an Intent that will start the MainActivity
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            // Add extra to indicate we want to start from splash screen
            putExtra("start_destination", "splash")
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Time to Return to FitScale!")
            .setContentText("Continue your fitness journey - tap to open")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("It's been 30 seconds since you last used FitScale. Keep up your momentum and continue your fitness journey! Tap to return to the app."))
            .setSmallIcon(R.mipmap.fitscalelogo)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        // Vibrate
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 500, 200, 500), -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(longArrayOf(0, 500, 200, 500), -1)
        }

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(inactivityRunnable)
    }
}