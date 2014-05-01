import itertools as it
from datafinger.models import *

from django.http import Http404, HttpResponse, HttpResponseRedirect, HttpRequest
from django.views.generic import ListView
from django.forms.models import modelformset_factory
from django.shortcuts import render_to_response
from django.template import RequestContext
from django.core.context_processors import csrf
from django.contrib.auth import authenticate, login, logout
from django.core.exceptions import ObjectDoesNotExist

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
    if not request.user.is_authenticated():
        return HttpResponseRedirect('/logon/')

    if request.method == 'POST':
        c = {}
        c.update(csrf(request))
        form = DeviceForm(request.POST)
        if form.is_valid():
            form.save()
            return HttpResponseRedirect("/devices/")
        else:
            return render_to_response('device.html', locals(),context_instance=RequestContext(request))
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

def longestSubstringFinder(string1, string2):
    answer = ""
    len1, len2 = len(string1), len(string2)
    for i in range(len1):
        match = ""
        for j in range(len2):
            if (i + j < len1 and string1[i + j] == string2[j]):
                match += string2[j]
            else:
                if (len(match) > len(answer)): answer = match
                match = ""
    return answer

def sync(request):
    finger = FINGERPRINT.objects.all().order_by('dhcp_fingerprint')
    for fingerprint in finger:
        try:
            common_string = long_substr([fingerprint.vendor_id,fingerprint.user_agent])
            if common_string:
                try:
                    device = Device.objects.get(code=common_string)
                    if not fingerprint.device:
                        fingerprint.device = device
                        fingerprint.save()
                except ObjectDoesNotExist:
                    if len(common_string) > 4:
                        try:
                            device = Device.objects.get(code=common_string)
                        except ObjectDoesNotExist:
                            device = Device(code=common_string)
                            device.save()
                        if not fingerprint.device:
                            fingerprint.device = device
                            fingerprint.save()
            else:
                finger_compare = FINGERPRINT.objects.filter(vendor_id = fingerprint.vendor_id, device_id__isnull=False)
                for finger_c in finger_compare:
                    fingerprint.device = finger_c.device
                    fingerprint.save()
        except TypeError:
            pass
    return HttpResponseRedirect("/devices/")

def long_substr(data):
    substr = ''
    if len(data) > 1 and len(data[0]) > 0:
        for i in range(len(data[0])):
            for j in range(len(data[0])-i+1):
                if j > len(substr) and is_substr(data[0][i:i+j], data):
                    substr = data[0][i:i+j]
    return substr

def is_substr(find, data):
    if len(data) < 1 and len(find) < 1:
        return False
    for i in range(len(data)):
        if find not in data[i]:
            return False
    return True
