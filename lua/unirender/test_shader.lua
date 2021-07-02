
function EmissionBSDF:Initialize()
	self.inColor = self:AddInputSocket("color",Color.White)
	self.outBsdf = self:AddOutputSocket("bsdf")
end
function EmissionBSDF:InitializeShader()
	local e = self:AddNode(unirender.NODE_TYPE_EMISSION)
	e:SetColor(self.m_color)
	e:SetStrength(1.0)
	self:Link(self.inColor,e.inColor)


	--e.outBsdf
end

unirender.register_node("emission_test",function(inputData)
	local e = self:AddNode(unirender.NODE_TYPE_EMISSION)
	e:SetColor(self.m_color)
	e:SetStrength(1.0)
end)



function ToonBSDF:Initialize(mat)
	local a = mat:GetAlpha()

	:LinkToAlbedo()
	mat:GetData()
	etc

	self.m_color = Color.Red
	self.m_inColor = x
	self.m_outBSDF = y


	-- Inputs / Outputs?
end
function ToonBSDF:INitializeAlbedo()
	
end
local function shader_test()
	-- ShaderDesc
	-- ->Generate()
	local e = self:AddNode(unirender.NODE_TYPE_EMISSION)
	e:SetColor(self.m_color)
	e:SetStrength(1.0)

	self:Link(e,self:GetOutputNode().inSurface)
end