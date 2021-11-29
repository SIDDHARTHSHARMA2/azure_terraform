import base64
data = open("init.yaml", "rb").read()
encoded = base64.b64encode(data)
print(encoded)
# data = base64.b64decode(encoded)
# print(data)