from datafinger.models import *

from django.http import Http404, HttpResponse, HttpResponseRedirect, HttpRequest
from django.views.generic import ListView
from django.forms.models import modelformset_factory
from django.shortcuts import render_to_response
from django.template import RequestContext
from django.core.context_processors import csrf
from django.contrib.auth import authenticate, login, logout

def logon(request):
    if request.user.is_authenticated():
        return HttpResponseRedirect("/fingerprints/")
    if request.POST:
        c = {}
        c.update(csrf(request))
        username = request.POST['username']
        password = request.POST['password']
        user = authenticate(username=username, password=password)
        if user is not None:
            if user.is_active:
                try:
                    ipsource = request.META['HTTP_X_FORWARDED_FOR']
                    ipsource = ipsource.split(",")[0]
                except:
                    ipsource = request.META['REMOTE_ADDR']
                    login(request, user)
                return HttpResponseRedirect("/fingerprints/")
        else:
            return render_to_response('logon.html',context_instance=RequestContext(request))
    else:
        return render_to_response('logon.html',context_instance=RequestContext(request))
 
def disconnect(request):
    c = {}
    c.update(csrf(request)) 
    logout(request)
    return HttpResponseRedirect("/logon/")

class dhcp(ListView):
    template_name = 'fingerprint.html'
    queryset = FINGERPRINT.objects.order_by('dhcp_fingerprint')
    context_object_name = 'dhcp'

class device(ListView):
    template_name = 'device.html'
    queryset = Device.objects.order_by('device_desc')
    context_object_name = 'device'

class devicefamily(ListView):
    template_name = 'devicefamily.html'
    queryset = Device_Family.objects.order_by('device_family')
    context_object_name = 'Device_Family'


class osfamily(ListView):
    template_name = 'osfamily.html'
    queryset = OS_Family.objects.order_by('os_family')
    context_object_name = 'os_family'


class ostype(ListView):
    template_name = 'ostype.html'
    queryset = OS_Type.objects.order_by('os_type')
    context_object_name = 'os_type'

class os(ListView):
    template_name = 'os.html'
    queryset = OS.objects.order_by('os')
    context_object_name = 'os'

class mac(ListView):
    template_name = 'mac.html'
    queryset = MAC.objects.order_by('oui')
    context_object_name = 'mac'

def fingerprint_edit(request,nid):
    fingerprint = FINGERPRINT.objects.get(id=nid)
    form = FINGERPRINTForm(instance=fingerprint)
    return render_to_response('fingerprint.html', locals(),context_instance=RequestContext(request))

def fingerprint_delete(request,nid):
    if not request.user.is_authenticated():
        return HttpResponseRedirect("/logon/")
    fingerprint = FINGERPRINT.objects.get(id=nid)
    fingerprint.delete()
    return HttpResponseRedirect("/fingerprints/")

def device_edit(request,nid):
    device = Device.objects.get(id=nid)
    form = DeviceForm(instance=device)
    return render_to_response('device.html', locals(),context_instance=RequestContext(request))

def device_delete(request,nid):
    if not request.user.is_authenticated():
        return HttpResponseRedirect("/logon/")
    device = Device.objects.get(id=nid)
    device.delete()
    return HttpResponseRedirect("/devices/")

def devicefamily_edit(request,nid):
    device = Device_Family.objects.get(id=nid)
    form = Device_FamilyForm(instance=device)
    return render_to_response('device.html', locals(),context_instance=RequestContext(request))

def devicefamily_delete(request,nid):
    if not request.user.is_authenticated():
        return HttpResponseRedirect("/logon/")
    device = Device_Family.objects.get(id=nid)
    device.delete()
    return HttpResponseRedirect("/devices/")

def os_edit(request,nid):
    os = OS.objects.get(id=nid)
    form = OSForm(instance=os)
    return render_to_response('os.html', locals(),context_instance=RequestContext(request))

def os_delete(request,nid):
    if not request.user.is_authenticated():
        return HttpResponseRedirect("/logon/")
    os = OS.objects.get(id=nid)
    os.delete()
    return HttpResponseRedirect("/os/")

def osfamily_edit(request,nid):
    os = OS_Family.objects.get(id=nid)
    form = OS_FamilyForm(instance=os)
    return render_to_response('os.html', locals(),context_instance=RequestContext(request))

def osfamily_delete(request,nid):
    if not request.user.is_authenticated():
        return HttpResponseRedirect("/logon/")
    os = OS_Family.objects.get(id=nid)
    os.delete()
    return HttpResponseRedirect("/os/")

def ostype_edit(request,nid):
    os = OS_Type.objects.get(id=nid)
    form = OS_TypeForm(instance=os)
    return render_to_response('os.html', locals(),context_instance=RequestContext(request))

def ostype_delete(request,nid):
    if not request.user.is_authenticated():
        return HttpResponseRedirect("/logon/")
    os = OS_Type.objects.get(id=nid)
    os.delete()
    return HttpResponseRedirect("/os/")

def mac_edit(request,nid):
    mac = MAC.objects.get(id=nid)
    form = MACForm(instance=mac)
    return render_to_response('mac.html', locals(),context_instance=RequestContext(request))

def mac_delete(request,nid):
    if not request.user.is_authenticated():
        return HttpResponseRedirect("/logon/")
    os = MAC.objects.get(id=nid)
    os.delete()
    return HttpResponseRedirect("/mac/")
