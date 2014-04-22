from django.contrib import admin
from datafinger.models import *


class FamilyAdmin(admin.ModelAdmin):
    list_display = ['device_family']

class DeviceAdmin(admin.ModelAdmin):
    list_display = ('code', 'device_desc','family')

class OS_FamilyAdmin(admin.ModelAdmin):
    list_display = ['os_family']

class OSAdmin(admin.ModelAdmin):
    list_display = ('os','os_type')

class MACAdmin(admin.ModelAdmin):
    list_display = ['oui']

class FINGERPRINTAdmin(admin.ModelAdmin):
    list_display = ('dhcp_fingerprint','vendor_id', 'uaprof', 'user_agent','is_mac', 'is_unix', 'is_windows', 'is_mobile', 'is_tablet', 'suites')

class OS_TypeAdmin(admin.ModelAdmin):
    list_display = ('os_type','os_family')


admin.site.register(Device_Family, FamilyAdmin)
admin.site.register(Device, DeviceAdmin)
admin.site.register(OS_Family, OS_FamilyAdmin)
admin.site.register(OS_Type, OS_TypeAdmin)
admin.site.register(OS, OSAdmin)
admin.site.register(MAC, MACAdmin)
admin.site.register(FINGERPRINT, FINGERPRINTAdmin)


