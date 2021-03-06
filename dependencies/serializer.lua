local Serializer = {}

do
    local CENTER_OFFSET = Vector3.new(1, 0, 0)

    Serializer.__index = Serializer

    setmetatable(Serializer, {
        __tostring = function()
            return "Serializer"
        end
    })

    function Serializer.new(Start, End)
        return setmetatable({
            Start = Start,
            End = End
        }, Serializer)
    end

    function Serializer:Round(Number) 
        if typeof(Number) == "number" then
            return math.round(Number / 3) * 3
        end
    end

    function Serializer:Format(CF)
        local x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33 = CF:components()
        return CFrame.new(self:Round(x), self:Round(y), self:Round(z), m11, m12, m13, m21, m22, m23, m31, m32, m33)
    end

    function Serializer:SetStart(Start)
        self.Start = Start
    end

    function Serializer:SetEnd(End)
        self.End = End
    end

    function Serializer:Serialize()
        local Start, End = Vector3.new(math.min(self.Start.X, self.End.X), math.min(self.Start.Y, self.End.Y), math.min(self.Start.Z, self.End.Z)), Vector3.new(math.max(self.Start.X, self.End.X), math.max(self.Start.Y, self.End.Y), math.max(self.Start.Z, self.End.Z))
        local Region = Region3.new(Start, End)
        local Output = {}

        local Model = Instance.new("Model")

        for i, v in next, workspace:FindPartsInRegion3(Region, nil, math.huge) do
            if v.Parent.Name == "Blocks" then
                local Clone = v:Clone()

                if not (Clone:FindFirstChild("Text") or Clone:FindFirstChild("top") or Clone:FindFirstChild("bottom")) then
                    Clone:ClearAllChildren()
                end

                Clone.Parent = Model
                
                if Output[v.Name] == nil then 
                    Output[v.Name] = {}
                end
            end
        end
        
        local CF, Size = Model:GetBoundingBox()
        local Start, End = CF.Position - Size / 2, CF.Position + Size / 2

        local Center = self:Format(CFrame.new((Start + End) / 2)) - CENTER_OFFSET

        for i, v in next, Model:GetChildren() do
            local Inserted = {}
            if v.ClassName == "Model" then
                Inserted.C = {Center:ToObjectSpace(v.PrimaryPart.CFrame):components()}
            elseif v:IsA("BasePart") then
                Inserted.C = {Center:ToObjectSpace(v.CFrame):components()};
                if v:FindFirstChild("bottom") and v.bottom.Transparency == 1 then
                    Inserted.U = true
                end
                if v:FindFirstChild("Text") then
                    Inserted.T = v.Text.Value
                end
            end
            table.insert(Output[v.Name], Inserted)
        end

        return {Size = {Size.X, Size.Y, Size.Z}, Blocks = Output}
    end
end

return Serializer
