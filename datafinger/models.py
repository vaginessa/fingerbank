from django.db import models
from django.forms import ModelForm

class Device_Family(models.Model):
    device_family = models.CharField(max_length=50)
    def __str__(self):
        return self.device_family

class Device_FamilyForm(ModelForm):
    class Meta:
        model = Device_Family
        fields = ['device_family']

class Device(models.Model):
    code = models.CharField(max_length=20)
    family = models.ForeignKey(Device_Family)
    device_desc = models.CharField(max_length=50)
    def __str__(self):
        return self.code

class DeviceForm(ModelForm):
    class Meta:
        model = Device
        fields = ['code', 'family', 'device_desc']

class OS_Family(models.Model):
    os_family = models.CharField(max_length=50)
    def __str__(self):
        return self.os_family

class OS_FamilyForm(ModelForm):
    class Meta:
        model = OS_Family
        fields = ['os_family']

class OS_Type(models.Model):
    os_family = models.ForeignKey(OS_Family)
    os_type = models.CharField(max_length=50)
    def __str__(self):
        return self.os_type

class OS_TypeForm(ModelForm):
    class Meta:
        model = OS_Type
        fields = ['os_family', 'os_type']

class OS(models.Model):
    os_type = models.ForeignKey(OS_Type)
    device = models.ManyToManyField(Device)
    os = models.CharField(max_length=50)
    def __str__(self):
        return self.os

class OSForm(ModelForm):
    class Meta:
        model = OS
        fields = ['os', 'device', 'os_type']

class MAC(models.Model):
    device = models.ManyToManyField(Device)
    oui = models.CharField(max_length=6)
    def __str__(self):
        return self.oui

class MACForm(ModelForm):
    class Meta:
        model = MAC
        fields = ['oui', 'device']

class FINGERPRINT(models.Model):
    os = models.ManyToManyField(OS)
    device = models.ManyToManyField(Device)
    dhcp_hash = models.CharField(max_length=32)
    dhcp_fingerprint = models.CharField(max_length=150, blank=True, null=True)
    vendor_id = models.CharField(max_length=100, blank=True, null=True)
    http_hash = models.CharField(max_length=32, blank=True, null=True)
    user_agent = models.CharField(max_length=250, blank=True, null=True)
    uaprof = models.CharField(max_length=100, blank=True, null=True)
    suites = models.CharField(max_length=200, blank=True, null=True)
    device_name = models.CharField(max_length=50, blank=True, null=True)
    is_mac = models.CharField(max_length=1, blank=True, null=True, default='0')
    is_windows = models.CharField(max_length=1, blank=True, null=True, default='0')
    is_unix = models.CharField(max_length=1, blank=True, null=True, default='0')
    is_mobile = models.CharField(max_length=1, blank=True, null=True, default='0')
    is_tablet = models.CharField(max_length=1, blank=True, null=True, default='0')
    os_string = models.CharField(max_length=50, blank=True, null=True)

    def __str__(self):
        return self.dhcp_hash

class FINGERPRINTForm(ModelForm):
    class Meta:
        model = FINGERPRINT
        fields = ['dhcp_hash', 'dhcp_fingerprint', 'vendor_id', 'os', 'device']


