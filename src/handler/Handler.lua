local Handler = class("Handler")

Handler.response = {}
Handler.request = {}

function Handler:ctor( )

end

function Handler:merge (dest, t)
    if not dest or not t then return end
    for k, v in pairs (t) do
        if type(v) == "table" then
            dest[k] = {}
            self:merge(dest[k], v)
        else
            dest[k] = v
        end
    end
end

function Handler:regHandler(request, response )
    self:merge(response, self.response)
    self:merge(request, self.request)
end

return Handler