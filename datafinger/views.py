from datafinger.models import *

from django.http import Http404, HttpResponse, HttpResponseRedirect, HttpRequest
from django.views.generic import ListView
from django.forms.models import modelformset_factory
from django.shortcuts import render_to_response

def logon(request):
    if request.user.is_authenticated():
        return HttpResponseRedirect("/finger/")
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
                return HttpResponseRedirect("/finger/")
    else:
        return render_to_response('logon.html',context_instance=RequestContext(request))
 
def disconnect(request):
    c = {}
    c.update(csrf(request)) 
    logout(request)
    return HttpResponseRedirect("/logon/")

class dhcp(ListView):
    template_name = 'home.html'
    queryset = FINGERPRINT.objects.order_by('dhcp_fingerprint')
    context_object_name = 'dhcp'

def test(request):
    #DHCPFormu = DHCPForm()
    FINGERPRINTForm = modelformset_factory(FINGERPRINT)
    if request.method == 'POST':
        formset = FINGERPRINTForm(request.POST, request.FILES)
        if formset.is_valid():
            formset.save()
    else:
        formset = FINGERPRINTForm()
    return render_to_response('dhcp.html', {"formset": formset})
