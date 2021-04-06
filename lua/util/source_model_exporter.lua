

include("log.lua")

pfm.register_log_category("se_model_export")

util.register_class("util.QC")
function util.QC:__init()
	self.m_sequences = {}
	self.m_materialPaths = {}
	self.m_meshes = {}
	self.m_parameters = {}
	self.m_modelName = "model"
end
function util.QC:AddSequence(name,fileName)
	log.msg("Adding sequence '" .. name .. "' ('" .. fileName .. "')...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
	table.insert(self.m_sequences,table.concat({"$sequence","\"" .. name .. "\"","\"" .. fileName .. "\""}," "))
end
function util.QC:AddMaterialPath(path)
	log.msg("Adding material path '" .. path .. "'...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
	table.insert(self.m_materialPaths,table.concat({"$cdmaterials","\"" .. path .. "\""}," "))
end
function util.QC:AddMesh(meshName,meshPath)
	log.msg("Adding mesh '" .. meshName .. "' ('" .. meshPath .. "')...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
	-- TODO: Use $model with $maxverts 65530
	table.insert(self.m_meshes,table.concat({"$body","\"" .. meshName .. "\"","\"" .. meshPath .. "\""}," "))
end
function util.QC:AddParameter(key,val)
	if(val == nil) then
		log.msg("Adding parameter '" .. key .. "'...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
		table.insert(self.m_parameters,key)
		return
	end
	log.msg("Adding parameter '" .. key .. "' = '" .. val .. "'...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
	table.insert(self.m_parameters,table.concat(key,"\"" .. val .. "\""," "))
end
function util.QC:SetModelName(name) self.m_modelName = name end
function util.QC:Generate()
	--return table.concat(self.m_contents,"\n")
	log.msg("Generating QC file for model '" .. self.m_modelName .. "'...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)

	return [[
$modelname	"]] .. self.m_modelName .. [[.mdl"

]] .. table.concat(self.m_meshes,"\n") .. [[

// $staticprop
$surfaceprop	combine_metal
]] .. table.concat(self.m_materialPaths,"\n") .. [[

]] .. table.concat(self.m_sequences,"\n") .. [[

]] .. table.concat(self.m_parameters,"\n") .. [[

]]
end

local rotToSmd = EulerAngles(90,0,0):ToQuaternion()
util.register_class("util.SMDBuilder")
function util.SMDBuilder.transform_pose(pose)
	pose:RotateGlobal(rotToSmd)
	return pose
end
function util.SMDBuilder.transform_pos(pos)
	pos:Rotate(rotToSmd)
	return pos
end
function util.SMDBuilder.transform_rot(rot)
	rot:Set(rotToSmd *rot)
	return rot
end
function util.SMDBuilder.quat_to_euler_angles(q)
	-- This creates incorrect results for some reason?
	--[[local ang = q:ToEulerAngles()
	return EulerAngles(math.rad(ang.p),math.rad(ang.y),math.rad(ang.r))]]

	return EulerAngles(
		math.atan2(2 *(q.w *q.x +q.y *q.z),1 -2 *(q.x *q.x +q.y *q.y)),
		math.asin(2 *(q.w *q.y -q.z *q.x)),
		math.atan2(2 *(q.w *q.z +q.x *q.y),1 -2 *(q.y *q.y +q.z *q.z))
	)
end
function util.SMDBuilder:__init()
	self.m_contents = {}
end
function util.SMDBuilder.create_from_animation(anim,skeleton)
	local smdBuilder = util.SMDBuilder()
	smdBuilder:AddSkeleton(skeleton)
	smdBuilder:AddAnimation(skeleton,anim)
	return smdBuilder
end
function util.SMDBuilder:AddLine(line)
	table.insert(self.m_contents,line)
end
function util.SMDBuilder:AddVertex(v,vw)
	local parentBone = 0
	local pos = util.SMDBuilder.transform_pos(v.position)
	local c = {
		parentBone,
		pos.x,pos.y,pos.z,
		v.normal.x,-v.normal.z,v.normal.y,
		v.uv.x,1.0 -v.uv.y
	}
	if(vw ~= nil) then
		local nLinks = 0
		for i=0,3 do
			if(vw.boneIds:Get(i) ~= -1) then nLinks = nLinks +1 end
		end
		if(nLinks > 0) then
			table.insert(c,nLinks)
			for i=0,3 do
				if(vw.boneIds:Get(i) ~= -1) then
					table.insert(c,vw.boneIds:Get(i))
					table.insert(c,vw.weights:Get(i))
				end
			end
		end
	end
	self:AddLine(table.concat(c," "))
end
function util.SMDBuilder:AddSkeleton(skeleton)
	self:AddLine("nodes")

	for i,bone in ipairs(skeleton:GetBones()) do
		local parent = bone:GetParent()
		local c = {
			i -1,
			"\"" .. bone:GetName() .. "\"",
			parent ~= nil and parent:GetID() or -1
		}
		self:AddLine(table.concat(c," "))
	end

	self:AddLine("end")
end
function util.SMDBuilder:AddAnimation(skeleton,anim)
	self:AddLine("skeleton")
	for i,frame in ipairs(anim:GetFrames()) do
		self:AddLine("time " .. i -1)
		self:AddFrame(skeleton,frame,anim)
	end
	self:AddLine("end")
end
function util.SMDBuilder:AddReferencePose(skeleton,ref)
	self:AddLine("skeleton")
	self:AddLine("time 0")
	local cpy = ref:Copy()
	cpy:Localize(skeleton)
	self:AddFrame(skeleton,cpy)
	self:AddLine("end")
end
function util.SMDBuilder:AddFrame(skeleton,frame,anim)
	for i=0,frame:GetBoneCount() -1 do
		local boneId = i
		if(anim ~= nil) then boneId = anim:GetBoneId(i) end

		local pose = frame:GetBonePose(boneId)
		if(skeleton:IsRootBone(boneId)) then pose = util.SMDBuilder.transform_pose(pose) end
		local pos = pose:GetOrigin()
		local ang = util.SMDBuilder.quat_to_euler_angles(pose:GetRotation())
		local c = {
			i,
			pos.x,pos.y,pos.z,
			util.round_string(ang.p,6),util.round_string(ang.y,6),util.round_string(ang.r,6)
		}
		self:AddLine(table.concat(c," "))
	end
end
function util.SMDBuilder:AddMesh(mdl,subMesh,mat)
	local matName = file.get_file_name(file.remove_file_extension(mat:GetName()))
	self:AddLine("triangles")

	local tris = subMesh:GetTriangles()
	local vweights = subMesh:GetVertexWeights()
	local numTris = #tris
	if(numTris > 0) then
		for i=0,numTris -1,3 do
			local idx0 = tris[i +1]
			local idx1 = tris[i +2]
			local idx2 = tris[i +3]
			local v0 = subMesh:GetVertex(idx0)
			local v1 = subMesh:GetVertex(idx1)
			local v2 = subMesh:GetVertex(idx2)

			self:AddLine(matName)
			self:AddVertex(v0,vweights[idx0 +1])
			self:AddVertex(v1,vweights[idx1 +1])
			self:AddVertex(v2,vweights[idx2 +1])
		end
	end
	self:AddLine("end")
end
function util.SMDBuilder:Generate()
	return table.concat(self.m_contents,"\n")
end






util.register_class("util.VmtBuilder")
function util.VmtBuilder:__init(mat)
	self.m_material = mat
	self.m_parameters = {}
	self.m_shader = "VertexLitGeneric"
end
function util.VmtBuilder:SetShader(shader) self.m_shader = shader end
function util.VmtBuilder:AddParameter(k,v)
	table.insert(self.m_parameters,"\"" .. k .. "\" " .. v)
end
--[["VertexLitGeneric"
{
     "$basetexture" "Models/Combine_soldier/Combine_elite"
     "$bumpmap" "models/combine_soldier/combine_elite_normal"
     "$envmap" "env_cubemap"
     "$normalmapalphaenvmapmask" 1
     "$envmapcontrast" 1
     "$model" 1
     "$selfillum" 1
}]]
function util.VmtBuilder:Generate(outputDir)
	local mat = self.m_material
	local matPath = file.remove_file_extension(mat:GetName())
	local relOutputDir = file.get_file_path(matPath)
	outputDir = outputDir .. relOutputDir

	local contents = "\"" .. self.m_shader .. "\"\n{\n\t"
	contents = contents .. table.concat(self.m_parameters,"\n\t")
	contents = contents .. "\n}"

	local vmtPath = file.get_file_name(matPath) .. ".vmt"
	file.write(outputDir .. vmtPath,contents)
	return relOutputDir .. vmtPath
end








util.register_class("util.SourceEngineModelBuilder")
function util.SourceEngineModelBuilder:__init(mdl)
	self.m_model = mdl
end

function util.SourceEngineModelBuilder:Generate()
	local outputDir = "export/"

	local mdl = self.m_model

	local convertToFakePbr = false
	for _,mat in ipairs(mdl:GetMaterials()) do
		local rmaMap = mat:GetTextureInfo("rma_map")
		if(rmaMap ~= nil) then
			local name = asset.get_normalized_path(rmaMap:GetName(),asset.TYPE_TEXTURE)
			if(name ~= "pbr/rma_neutral") then
				log.msg("Found non-standard RMA map '" .. name .. "' in model '" .. mdl:GetName() .. "'! Enabling fake-pbr conversion...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT,pfm.LOG_SEVERITY_WARNING)
				convertToFakePbr = true
				break
			end
		end
	end

	if(convertToFakePbr == false) then
		log.msg("No non-standard RMA map found in model '" .. mdl:GetName() .. "' found! Disabling fake-pbr conversion...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT,pfm.LOG_SEVERITY_WARNING)
	end

	local mdlPath = file.remove_file_extension(mdl:GetName())
	outputDir = outputDir .. file.get_file_name(mdlPath) .. "/"

	local skeleton = mdl:GetSkeleton()

	local qc = util.QC()
	for _,path in ipairs(mdl:GetMaterialPaths()) do
		qc:AddMaterialPath(path)
	end
	qc:SetModelName(mdlPath)

	if(convertToFakePbr) then qc:AddParameter("$mostlyopaque") end

	local function export_mesh(subMesh,meshName,mat)
		local smdBuilder = util.SMDBuilder()
		smdBuilder:AddSkeleton(skeleton)
		smdBuilder:AddReferencePose(skeleton,mdl:GetReferencePose())
		smdBuilder:AddMesh(mdl,subMesh,mat)
		local meshPath = "meshes/" .. meshName .. ".smd"
		qc:AddMesh(meshName,meshPath)
		file.write(outputDir .. meshPath,smdBuilder:Generate())
	end

	local subMeshIdx = 0
	local materials = {}
	local tmpMaterials = {}
	for _,meshGroup in ipairs(mdl:GetMeshGroups()) do
		for _,mesh in ipairs(meshGroup:GetMeshes()) do
			for _,subMesh in ipairs(mesh:GetSubMeshes()) do
				local mat = mdl:GetMaterial(subMesh:GetSkinTextureIndex())
				if(mat ~= nil) then
					local useFakePbrForThisMesh = convertToFakePbr
					if(useFakePbrForThisMesh) then
						local texInfo = mat:GetTextureInfo("albedo_map")
						if(texInfo ~= nil) then
							local baseTexName = asset.get_normalized_path(texInfo:GetName(),asset.TYPE_TEXTURE)

							local matName = file.remove_file_extension(mat:GetName())
							local matNameBase = matName .. "_base.wmi"
							local matNameCh = matName .. "_ch.wmi"
							local matNameSpec = matName .. "_spec.wmi"
							local matBase = game.get_material(matNameBase)
							local matCh = game.get_material(matNameCh)
							local matSpec = game.get_material(matNameSpec)
							if(matBase == nil) then
								local texAlbedo,texChMask,texExponentMap,texNormalMap = util.convert_pbr_to_fake_pbr(mat)
								if(texAlbedo ~= false) then
									matBase =  game.create_material(matNameBase,"fake_pbr_base")
									matBase:SetTexture("basetexture",texAlbedo,baseTexName .. "_base")
									matBase:SetTexture("bumpmap",texNormalMap,baseTexName .. "_n")
									matBase:SetTexture("phongexponenttexture",texExponentMap,baseTexName .. "_e")
									tmpMaterials[matBase:GetName()] = true

									matCh = game.create_material(matNameCh,"fake_pbr_ch")
									matCh:SetTexture("basetexture",texAlbedo,baseTexName .. "_base")
									matCh:SetTexture("normalmap",texNormalMap,baseTexName .. "_n")
									matCh:SetTexture("maskmap2",texChMask,baseTexName .. "_ch")
									tmpMaterials[matCh:GetName()] = true

									matSpec = game.create_material(matNameSpec,"fake_pbr_spec")
									matSpec:SetTexture("basetexture",texAlbedo,baseTexName .. "_base")
									matSpec:SetTexture("bumpmap",texNormalMap,baseTexName .. "_n")
									matSpec:SetTexture("phongexponenttexture",texExponentMap,baseTexName .. "_e")
									tmpMaterials[matSpec:GetName()] = true
								else
									log.msg("Unable to generate fake pbr textures from material '" .. mat:GetName() .. "'!",pfm.LOG_CATEGORY_SE_MODEL_EXPORT,pfm.LOG_SEVERITY_WARNING)
								end
							end
							if(matBase ~= nil) then
								export_mesh(subMesh,"mesh_base" .. subMeshIdx,matBase)
								export_mesh(subMesh,"mesh_ch" .. subMeshIdx,matCh)
								export_mesh(subMesh,"mesh_spec" .. subMeshIdx,matSpec)
								materials[matBase:GetName()] = matBase
								materials[matSpec:GetName()] = matSpec
								materials[matCh:GetName()] = matCh
							else useFakePbrForThisMesh = false end -- Revert to default mode
						end
					end
					if(useFakePbrForThisMesh == false) then
						if(convertToFakePbr) then
							log.msg("Reverting to non-fake-pbr method for mesh with material '" .. mat:GetName() .. "'!",pfm.LOG_CATEGORY_SE_MODEL_EXPORT,pfm.LOG_SEVERITY_WARNING)
						end
						export_mesh(subMesh,"mesh" .. subMeshIdx,mat)
						materials[mat:GetName()] = mat
					end
					subMeshIdx = subMeshIdx +1
				end
			end
		end
	end

	for i,anim in ipairs(mdl:GetAnimations()) do
		local name = mdl:GetAnimationName(i -1)
		local fileName = "animations/" .. name .. ".smd"
		file.write(outputDir .. fileName,util.SMDBuilder.create_from_animation(anim,skeleton):Generate())

		qc:AddSequence(name,fileName)
	end

	local materialList = {}
	for name,mat in pairs(materials) do table.insert(materialList,mat) end
	local qcPath = outputDir .. file.get_file_name(mdlPath) .. ".qc"
	file.write(qcPath,qc:Generate())
	return {
		qcPath = qcPath,
		modelPath = mdlPath .. ".mdl",
		outputDir = outputDir,
		materials = materialList,
		tmpMaterials = tmpMaterials
	}
end

function util.export_source_engine_material(mat,outputDir)
	if(type(mat) == "string") then mat = game.load_material(mat) end

	local vmtBuilder = util.VmtBuilder(mat)
	local filePaths = {}
	local function add_texture(vmtIdentifier,identifier,isNormalMap,outputFormat)
		isNormalMap = isNormalMap or false
		local texInfo = mat:GetTextureInfo(identifier)
		local tex = (texInfo ~= nil) and texInfo:GetTexture() or nil
		local prTex = (tex ~= nil) and tex:GetVkTexture() or nil
		if(prTex ~= nil) then
			local img = prTex:GetImage()
			local relPath = asset.get_normalized_path(texInfo:GetName(),asset.TYPE_TEXTURE)
			local texOutputDir = relPath .. ".vtf"
			table.insert(filePaths,texOutputDir)
			texOutputDir = outputDir .. texOutputDir
			local srgb = true
			if(isNormalMap) then srgb = false end
			local generateMipmaps = false -- Mipmaps have already been generated during the compression stage
			local result = asset.export_texture_as_vtf(texOutputDir,img,srgb,isNormalMap,generateMipmaps,outputFormat)
			if(result == false) then
				log.msg("Failed to export image '" .. tostring(img) .. "' as VTF to '" .. texOutputDir .. "'!",pfm.LOG_CATEGORY_SE_MODEL_EXPORT,pfm.LOG_SEVERITY_WARNING)
			end

			vmtBuilder:AddParameter(vmtIdentifier,"\"" .. relPath .. "\"")
		else
			log.msg("Failed export texture '" .. vmtIdentifier .. "' for material '" .. mat:GetName() .. "': Texture '" .. identifier .. "' is invalid!",pfm.LOG_CATEGORY_SE_MODEL_EXPORT,pfm.LOG_SEVERITY_WARNING)
		end
	end
	local function copy_texture(tex)
		table.insert(filePaths,tex)
		file.create_path(outputDir .. file.get_file_path(tex))
		file.copy("materials/" .. tex,outputDir .. tex)
	end
	if(mat:GetShaderName() == "fake_pbr_base") then
		add_texture("$basetexture","basetexture",false,prosper.FORMAT_BC3_UNORM_BLOCK)
		add_texture("$bumpmap","bumpmap",true,prosper.FORMAT_BC3_UNORM_BLOCK)
		add_texture("$phongexponenttexture","phongexponenttexture",false,prosper.FORMAT_BC1_RGB_UNORM_BLOCK)

		vmtBuilder:AddParameter("$color2","\"[0 0 0]\"")
		vmtBuilder:AddParameter("$blendTintByBaseAlpha","1")
		vmtBuilder:AddParameter("$phong","1")
		vmtBuilder:AddParameter("$phongboost","9.9934895")
		vmtBuilder:AddParameter("$phongfresnelranges","\"[0.05 0.115 0.945]\"")
		vmtBuilder:AddParameter("$phongdisablehalflambert","1")
		vmtBuilder:AddParameter("$envmap","\"models/cubemaps/fallout4cube_dithered_grey\"")
		vmtBuilder:AddParameter("$normalmapalphaenvmapmask","1")
		vmtBuilder:AddParameter("$envmapfresnel","1")
		vmtBuilder:AddParameter("$envmaptint","\"[.2 .2 .2]\"")
		copy_texture("models/cubemaps/fallout4cube_dithered_grey.vtf")
	elseif(mat:GetShaderName() == "fake_pbr_ch") then
		vmtBuilder:SetShader("CustomHero")
		add_texture("$basetexture","basetexture",false,prosper.FORMAT_BC3_UNORM_BLOCK)
		add_texture("$normalmap","normalmap",true,prosper.FORMAT_BC3_UNORM_BLOCK)
		add_texture("$maskmap2","maskmap2",false,prosper.FORMAT_BC1_RGB_UNORM_BLOCK)

		vmtBuilder:AddParameter("$nocull","0")
		vmtBuilder:AddParameter("$additive","1")
		vmtBuilder:AddParameter("$specularexponent","20")
		vmtBuilder:AddParameter("$specularscale","0")
		vmtBuilder:AddParameter("$specularcolor","\"[1 1 1]\"")
		vmtBuilder:AddParameter("$rimlightcolor","\"[1 1 1]\"")
		vmtBuilder:AddParameter("$rimlightscale","0")
		vmtBuilder:AddParameter("$ambientscale","0")
		vmtBuilder:AddParameter("$envmap","\"models/cubemaps/fallout4cube_dithered_grey\"")
		vmtBuilder:AddParameter("$maskenvbymetalness","0")
		vmtBuilder:AddParameter("$metalnessblendtofull","1")
		vmtBuilder:AddParameter("$envmapintensity","0.225")
		copy_texture("models/cubemaps/fallout4cube_dithered_grey.vtf")
	elseif(mat:GetShaderName() == "fake_pbr_spec") then
		add_texture("$basetexture","basetexture",false,prosper.FORMAT_BC3_UNORM_BLOCK)
		add_texture("$bumpmap","bumpmap",true,prosper.FORMAT_BC3_UNORM_BLOCK)
		add_texture("$phongexponenttexture","phongexponenttexture",false,prosper.FORMAT_BC1_RGB_UNORM_BLOCK)

		vmtBuilder:AddParameter("$PhongAlbedoTint","1")
		vmtBuilder:AddParameter("$color2","\"[0 0 0]\"")
		vmtBuilder:AddParameter("$translucent","1")
		vmtBuilder:AddParameter("$phong","1")
		vmtBuilder:AddParameter("$phongboost","19.986979")
		vmtBuilder:AddParameter("$phongfresnelranges","\"[0.87 0.9 1]\"")
		vmtBuilder:AddParameter("$ambientocclusion","0.7")
	else
		add_texture("$basetexture","albedo_map")
		add_texture("$bumpmap","normal_map",true)
	end

	table.insert(filePaths,1,vmtBuilder:Generate(outputDir))
	return filePaths
end

function util.export_source_engine_models(models,gameIdentifier)
	local r = engine.load_library("mount_external/pr_mount_external")
	if(r ~= true) then
		console.print("WARNING: An error occured trying to load the 'pr_mount_external' module: ",r)
		return false,"Unable to load \"pr_mount_external\" module: " .. r
	end

	if(#gameIdentifier == 0) then
		log.msg("No game specified, attempting to locate Source Engine game with SDK tools...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
		gameIdentifier = source_engine.find_game_with_sdk_tools()
		if(gameIdentifier == false) then
			return false,"Unable to locate Source Engine game with hlmv and studiomdl SDK tools!"
		end
		log.msg("Found SDK tools in Source Engine game '" .. gameIdentifier .. "'!",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
	end

	local mdlName = models[1]
	local mdl = game.load_model(mdlName)
	if(mdl == nil) then return end -- TODO

	local builder = util.SourceEngineModelBuilder(mdl)
	local data = builder:Generate()

	local result,err = source_engine.compile_model(data.qcPath,gameIdentifier)
	if(result == false) then return result,err end

	local zipFiles = {}
	local materialFiles = {}
	for _,mat in ipairs(data.materials) do
		local filePaths = util.export_source_engine_material(mat,data.outputDir .. "materials/")
		console.print_table(filePaths)
		for _,filePath in ipairs(filePaths) do
			zipFiles["materials/" .. filePath] = data.outputDir .. "materials/" .. filePath
			materialFiles[data.outputDir .. "materials/" .. filePath] = "materials/" .. filePath
		end

		--[[if(data.tmpMaterials[mat:GetName()]) then
			-- The textures we use for fake pbr generation are fairly large, so we want to clear them from the cache asap...
			log.msg("Clearing temporary material '" .. mat:GetName() .. "' from cache...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
			mat:Reset()
		end]]
	end

	result,err = source_engine.extract_asset_files(materialFiles,gameIdentifier)
	if(result == false) then return result,err end

	source_engine.open_model_in_hlmv(data.modelPath,gameIdentifier)

	local extensions = {"dx80.vtx","dx90.vtx","mdl","sw.vtx","vvd"}
	local zipFileName = data.outputDir .. file.remove_file_extension(file.get_file_name(data.modelPath)) .. ".zip"
	for _,ext in ipairs(extensions) do
		local fname = "models/" .. file.remove_file_extension(data.modelPath) .. "." .. ext
		local f = file.open_external_asset_file(fname,gameIdentifier)
		if(f ~= nil) then
			zipFiles[fname] = {
				["contents"] = f:Read(f:Size())
			}
		end
	end
	log.msg("Packing zip-archive...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
	local result = util.pack_zip_archive(zipFileName,zipFiles)
	zipFileName = util.get_addon_path() .. zipFileName
	if(result) then util.open_path_in_explorer(file.get_file_path(zipFileName),file.get_file_name(zipFileName)) end
	log.msg("Done!",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
	return true
end

function util.convert_pbr_to_fake_pbr(mat)
	local function get_tex(identifier)
		local texInfo = mat:GetTextureInfo(identifier)
		local tex = (texInfo ~= nil) and texInfo:GetTexture() or nil
		return (tex ~= nil) and tex:GetVkTexture() or nil
	end
	local texAlbedo = get_tex("albedo_map")
	local texNormal = get_tex("normal_map")
	local texRma = get_tex("rma_map")

	if(texAlbedo == nil or texNormal == nil or texRma == nil) then return false end

	include("/shaders/util/fake_pbr.lua")
	local shaderFakePbr = shader.get("util_pbr_to_fake_pbr")
	if(util.is_valid(shaderFakePbr) == false) then return false end
	log.msg("Generating fake pbr textures for material '" .. mat:GetName() .. "'...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
	local ds = shaderFakePbr:CreateDescriptorSet(shader.FakePbr.DESCRIPTOR_SET_TEXTURE)

	ds:SetBindingTexture(shader.FakePbr.TEXTURE_BINDING_ALBEDO_MAP,texAlbedo)
	ds:SetBindingTexture(shader.FakePbr.TEXTURE_BINDING_NORMAL_MAP,texNormal)
	ds:SetBindingTexture(shader.FakePbr.TEXTURE_BINDING_RMA_MAP,texRma)

	-- Disabled because mipmaps for high-resolution textures and float-formats requires too much GPU memory, so we'll just generate mipmaps
	-- when we're converting to a compressed (DXT) format.
	local generateMipmaps = false

	local function create_texture(img)
		local samplerCreateInfo = prosper.SamplerCreateInfo()
		samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
		samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
		samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
		return prosper.create_texture(img,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),samplerCreateInfo)
	end
	local function create_image_texture(w,h,format,normalMap)
		normalMap = normalMap or false
		local size = prosper.get_byte_size(format)
		local nPixels = 0
		local numMipmaps = generateMipmaps and prosper.calculate_mipmap_count(w,h) or 1
		for i=0,numMipmaps -1 do
			local szMip = prosper.calculate_mipmap_size(w,h,i)
			nPixels = nPixels +szMip.x *szMip.y
		end
		size = nPixels *size
		log.msg("Allocating texture of " .. w .. "x" .. h .. " with format " .. prosper.format_to_string(format) .. " (~" .. util.get_pretty_bytes(size) .. ")...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
		local imgCreateInfo = prosper.ImageCreateInfo()
		imgCreateInfo.width = w
		imgCreateInfo.height = h
		imgCreateInfo.format = format
		if(numMipmaps > 1) then imgCreateInfo.flags = bit.bor(imgCreateInfo.flags,prosper.ImageCreateInfo.FLAG_FULL_MIPMAP_CHAIN_BIT) end
		if(normalMap) then imgCreateInfo.flags = bit.bor(imgCreateInfo.flags,prosper.ImageCreateInfo.FLAG_NORMAL_MAP_BIT)
		else imgCreateInfo.flags = bit.bor(imgCreateInfo.flags,prosper.ImageCreateInfo.FLAG_SRGB_BIT) end
		imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT,prosper.IMAGE_USAGE_TRANSFER_SRC_BIT,prosper.IMAGE_USAGE_TRANSFER_DST_BIT)
		imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
		imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
		imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL

		local img = prosper.create_image(imgCreateInfo)
		return create_texture(img)
	end
	local w = math.max(texAlbedo:GetWidth(),texNormal:GetWidth(),texRma:GetWidth())
	local h = math.max(texAlbedo:GetHeight(),texNormal:GetHeight(),texRma:GetHeight())
	local texAlbedo = create_image_texture(w,h,shader.FakePbr.RENDER_PASS_ALBEDO_MAP_FORMAT)
	local texChMask = create_image_texture(w,h,shader.FakePbr.RENDER_PASS_CH_MASK_FORMAT)
	local texExponentMap = create_image_texture(w,h,shader.FakePbr.RENDER_PASS_EXPONENT_MAP_FORMAT)
	local texNormalMap = create_image_texture(w,h,shader.FakePbr.RENDER_PASS_NORMAL_MAP_FORMAT,true)
	local textures = {texAlbedo,texChMask,texExponentMap,texNormalMap}

	local rt = prosper.create_render_target(prosper.RenderTargetCreateInfo(),textures,shaderFakePbr:GetRenderPass())

	local drawCmd = game.get_setup_command_buffer()

	if(drawCmd:RecordBeginRenderPass(prosper.RenderPassInfo(rt))) then
		shaderFakePbr:Draw(drawCmd,ds)
		drawCmd:RecordEndRenderPass()
	end
	if(generateMipmaps) then
		local function generate_mipmaps(img)
			drawCmd:RecordImageBarrier(img,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
			drawCmd:RecordGenerateMipmaps(img,prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,prosper.ACCESS_TRANSFER_WRITE_BIT,prosper.PIPELINE_STAGE_TRANSFER_BIT)
			-- Image is now in shader-read-only-optimal layout
		end
		log.msg("Generating mipmaps...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
		for _,tex in ipairs(textures) do
			generate_mipmaps(tex:GetImage())
		end
	else
		for _,tex in ipairs(textures) do
			drawCmd:RecordImageBarrier(tex:GetImage(),prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
		end
	end

	game.flush_setup_command_buffer()

	local drawCmd = game.get_setup_command_buffer()
	log.msg("Compressing fake pbr textures...",pfm.LOG_CATEGORY_SE_MODEL_EXPORT)
	local function to_compressed_image(img,compressedFormat)
		local createInfo = img:GetCreateInfo()
		createInfo.format = compressedFormat
		createInfo.flags = bit.bor(createInfo.flags,prosper.ImageCreateInfo.FLAG_FULL_MIPMAP_CHAIN_BIT) -- Mipmaps will automatically be generated through the copy
		return img:Copy(drawCmd,createInfo)
	end
	local imgAlbedoCompressed = to_compressed_image(texAlbedo:GetImage(),prosper.FORMAT_BC3_UNORM_BLOCK)
	local imgChMaskCompressed = to_compressed_image(texChMask:GetImage(),prosper.FORMAT_BC1_RGB_UNORM_BLOCK)
	local imgExponentMapCompressed = to_compressed_image(texExponentMap:GetImage(),prosper.FORMAT_BC1_RGB_UNORM_BLOCK)
	local imgNormalMapCompressed = to_compressed_image(texNormalMap:GetImage(),prosper.FORMAT_BC3_UNORM_BLOCK)
	game.flush_setup_command_buffer()

	texAlbedo = create_texture(imgAlbedoCompressed)
	texChMask = create_texture(imgChMaskCompressed)
	texExponentMap = create_texture(imgExponentMapCompressed)
	texNormalMap = create_texture(imgNormalMapCompressed)

	rt = nil
	drawCmd = nil
	textures = nil

	collectgarbage() -- Free memory for uncompressed images immediately

	return texAlbedo,texChMask,texExponentMap,texNormalMap
end
