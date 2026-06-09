"""
URL configuration for lamessin_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
"""
URL configuration for lamessin_backend project.
"""


"""
URL configuration for lamessin_backend project.
"""

"""
URL configuration for lamessin_backend project.
"""


from django.urls import path, include
from django.http import HttpResponseRedirect
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import login
from lamessin_app.models import Utilisateur
from lamessin_app.admin import admin_site


@csrf_exempt
def admin_auto_login(request):
    token = request.GET.get('token')
    if token:
        try:
            from rest_framework_simplejwt.tokens import AccessToken
            access_token = AccessToken(token)
            user_id = access_token['user_id']
            user = Utilisateur.objects.get(id=user_id)
            if user and user.is_superuser:
                login(request, user)
        except Exception as e:
            print(f"Erreur auto-login: {e}")
    return HttpResponseRedirect('/admin/')


urlpatterns = [
    path('jet/', include('jet.urls', 'jet')),
    path('admin-auto/', admin_auto_login),
    path('admin/', admin_site.urls),
    path('api/', include('lamessin_app.urls')),
]

