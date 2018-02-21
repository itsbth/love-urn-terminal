import json

def h2c(h):
    return f"(list {int(h[1:3], 16)} {int(h[3:5], 16)} {int(h[5:7], 16)})"

colors = json.load(open('scheme.json'))

print("(define *colors* (list")
for c in colors:
    print(h2c(c))
print("))")

