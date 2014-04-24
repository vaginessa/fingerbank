from django.conf.urls import patterns, include, url
from django.contrib import admin
admin.autodiscover()

from datafinger.views import dhcp, device, os, osfamily, ostype, devicefamily, mac

urlpatterns = patterns('',
    url(r'^/?$', 'datafinger.views.logon'),
    url(r'^logon/$', 'datafinger.views.logon'),
    url(r'^logout/$', 'datafinger.views.disconnect'),
    url(r'^fingerprints/$', dhcp.as_view()),
    url(r'^fingerprints/edit/(?P<nid>\d+)/$', 'datafinger.views.fingerprint_edit'),
    url(r'^fingerprints/del/(?P<nid>\d+)/$', 'datafinger.views.fingerprint_delete'),
    url(r'^devices/$', device.as_view()),
    url(r'^devices/edit/(?P<nid>\d+)/$', 'datafinger.views.device_edit'),
    url(r'^devices/del/(?P<nid>\d+)/$', 'datafinger.views.device_delete'),
    url(r'^devicesfamily/$', devicefamily.as_view()),
    url(r'^devicesfamily/edit/(?P<nid>\d+)/$', 'datafinger.views.devicefamily_edit'),
    url(r'^devicesfamily/del/(?P<nid>\d+)/$', 'datafinger.views.devicefamily_delete'),
    url(r'^osfamily/$', osfamily.as_view()),
    url(r'^osfamily/edit/(?P<nid>\d+)/$', 'datafinger.views.osfamily_edit'),
    url(r'^osfamily/del/(?P<nid>\d+)/$', 'datafinger.views.osfamily_delete'),
    url(r'^ostype/$', ostype.as_view()),
    url(r'^ostype/edit/(?P<nid>\d+)/$', 'datafinger.views.ostype_edit'),
    url(r'^ostype/del/(?P<nid>\d+)/$', 'datafinger.views.ostype_delete'),
    url(r'^os/$', os.as_view()),
    url(r'^os/edit/(?P<nid>\d+)/$', 'datafinger.views.os_edit'),
    url(r'^os/del/(?P<nid>\d+)/$', 'datafinger.views.os_delete'),
    url(r'^mac/$', mac.as_view()),
    url(r'^mac/edit/(?P<nid>\d+)/$', 'datafinger.views.mac_edit'),
    url(r'^mac/del/(?P<nid>\d+)/$', 'datafinger.views.mac_delete'),
    url(r'^admin/', include(admin.site.urls)),
)
