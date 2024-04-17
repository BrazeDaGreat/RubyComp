# Google Icons Add-On


def gicon(name, classes="")
    "<span class='#{classes} material-symbols-outlined'>#{name}</span>"
end

def gicon__init
    "<link rel='stylesheet' href='https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0' />"
end

def bicon__init
    '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">'
end

def bicon(name, classes="")
    "<i class='#{classes} bi bi-#{name}'></i>"
end