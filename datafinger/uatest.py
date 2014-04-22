from uasparser import UASparser  

uas_parser = UASparser('./')  
result = uas_parser.parse('Mozilla/5.0 (iPod; CPU iPhone OS 6_1 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Mobile/10B144') 
print result
