# ============================================
# REGLAS DE R8 / PROGUARD PARA BUILDS DE RELEASE
# ============================================
#
# Flutter activa minificación y ofuscación en los builds de release. Eso
# renombra clases y, salvo que se le indique lo contrario, descarta los
# metadatos que algunas librerías necesitan en tiempo de ejecución.
#
# Sin estas reglas la app compila y arranca bien, pero revienta al usar
# notificaciones — un fallo que NO aparece en debug, porque ahí R8 no corre.

# ── Gson ──────────────────────────────────────────────────────────────────
#
# Gson resuelve a qué tipo deserializar leyendo las firmas genéricas en
# runtime, vía TypeToken. R8 las borra por defecto, y entonces TypeToken se
# queda sin tipo y lanza:
#
#   IllegalStateException: TypeToken must be created with a type argument
#
# `Signature` es el atributo que preserva esos genéricos.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

-dontwarn sun.misc.**

# ── flutter_local_notifications ───────────────────────────────────────────
#
# El plugin persiste las notificaciones programadas en SharedPreferences
# serializándolas con Gson. Al cancelar una notificación vuelve a leer esa
# caché (cancel -> removeNotificationFromCache -> loadScheduledNotifications),
# que es donde estallaba: guardar preferencias dispara un reschedule, y el
# reschedule cancela antes de reprogramar.
-keep class com.dexterous.** { *; }
