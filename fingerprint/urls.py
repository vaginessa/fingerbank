from django.conf.urls import patterns, include, url
from django.contrib import admin
admin.autodiscover()

from datafinger.views import dhcp

urlpatterns = patterns('',
    url(r'^/?$', 'datafinger.views.logon'),
    url(r'^logon/$', 'datafinger.views.logon'),
    url(r'^logout/$', 'datafinger.views.disconnect'),
    url(r'^finger/$', dhcp.as_view()),
    url(r'^test/$', 'datafinger.views.test'),
    url(r'^admin/', include(admin.site.urls)),
)
