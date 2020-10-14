# Ensuring system using networkd
# So that we can add the ethernet configurations
PACKAGECONFIG_append = " networkd resolved"