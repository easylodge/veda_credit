module Helpers
  	
  	ACCESS = YAML.load_file('dev_veda_access.yml')
    ACCESS_URL = 'https://ctaau.vedaxml.com/cta/sys1'
    ACCESS_CODE = ACCESS["access_code"]
    ACCESS_PASSWORD = ACCESS["password"]
    ACCESS_SUBSCRIBER = ACCESS["subscriber_id"]
    ACCESS_SECURITY = ACCESS["security_code"]
    ACCESS_MODE = "test"

end