from django.apps import AppConfig

class LamessinAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'lamessin_app'

    def ready(self):
        import lamessin_app.signals

