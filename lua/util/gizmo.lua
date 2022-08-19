--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Gizmo = util.register_class("util.Gizmo")
function Gizmo:__init()
	self.m_hasClicked = false
	self.m_mouseLeft = false
	self.m_snapTranslation = false
	self.m_rayOrigin = Vector()
	self.m_rayDirection = Vector(0,0,1)
	self.m_interaction = {
		active = false,
		hover = false,
		initial_pose = math.ScaledTransform(),
		click_offset = Vector(0,0,0),
		interaction_mode = 0
	}
	self.m_camPosition = Vector()
end

function Gizmo:PlaneTranslationDragger(id,g,plane_normal,point)
    -- interaction_state & interaction = g.gizmos[id];

    -- Mouse clicked
    if (self.m_interactionStart) then self.m_interaction.initial_pose:SetOrigin(point) end
 
    if (self.m_mouseLeft) then
        -- Define the plane to contain the original position of the object
        local plane_point = self.m_interaction.initial_pose:GetOrigin();
        local r = { origin = self.m_rayOrigin, direction = self.m_rayDirection };

        -- If an intersection exists between the ray and the plane, place the object at that point
        local denom = r.direction:DotProduct(plane_normal);
        if (math.abs(denom) == 0) then return point end

        local t = (plane_point - r.origin):DotProduct(plane_normal) / denom;
        if (t < 0) then return point end

        point = r.origin + r.direction * t;

        if (self.m_snapTranslation) then point = snap(point, self.m_snapTranslation) end
    end
    return point
end

function Gizmo:AxisTranslationDragger(g, axis, point)
    -- interaction_state & interaction = g.gizmos[id];

    if (self.m_mouseLeft) then
        -- First apply a plane translation dragger with a plane that contains the desired axis and is oriented to face the camera
        local plane_tangent = axis:Cross(point - self.m_camPosition);
        local plane_normal = axis:Cross(plane_tangent);
        point = self:PlaneTranslationDragger(id, g, plane_normal, point);

        -- Constrain object motion to be along the desired axis
        point = self.m_interaction.initial_pose:GetOrigin() + axis * (point - self.m_interaction.initial_pose:GetOrigin()):DotProduct(axis);
    end
    return point
end

local function rotation_quat(axis,angle)
	local v = axis *math.sin(angle /2.0)
	return Quaternion(math.cos(angle /2.0),v.x,v.y,v.z)
end

local function qmul(a,b)
	return Quaternion(a.w*b.w - a.x*b.x - a.y*b.y - a.z*b.z, a.x*b.w + a.w*b.x + a.y*b.z - a.z*b.y, a.y*b.w + a.w*b.y + a.z*b.x - a.x*b.z, a.z*b.w + a.w*b.z + a.x*b.y - a.y*b.x)
end

local function intersect_ray_plane(ray,plane)
			--[[local d = debug.DrawInfo()
			d:SetColor(Color.Yellow)
			d:SetDuration(0.1)
			debug.draw_plane(plane:GetNormal(),plane:GetDistance(),d)]]

	local t = intersect.line_with_plane(ray.origin,ray.direction *100000,plane:GetNormal(),plane:GetDistance())
	if(t == false) then return nil end
    return t *100000
end

function Gizmo:AxisRotationDragger(id,g,axis,center,start_orientation,orientation)
    -- interaction_state & interaction = g.gizmos[id];

    if (self.m_mouseLeft) then
        local original_pose = math.Transform(self.m_interaction.initial_pose:GetOrigin(), start_orientation);
        local the_axis = axis:Copy()
        the_axis:Rotate(original_pose:GetRotation())
        the_axis:Normalize()
        local the_plane = { the_axis, the_axis:DotProduct(self.m_interaction.click_offset) };
        local r = { origin = self.m_rayOrigin, direction = self.m_rayDirection };

        local t = intersect_ray_plane(r, math.Plane(the_plane[1],the_plane[2]))
        if (t ~= nil) then
            local center_of_rotation = self.m_interaction.initial_pose:GetOrigin() + the_axis * the_axis:DotProduct(self.m_interaction.click_offset - self.m_interaction.initial_pose:GetOrigin());
            local arm1 = self.m_interaction.click_offset - center_of_rotation;
            if(arm1:LengthSqr() < 0.001) then
            	arm1 = vector.FORWARD
            else
           		arm1:Normalize()
           	end
            local arm2 = r.origin + r.direction * t - center_of_rotation;
            arm2:Normalize()

			local d = debug.DrawInfo()
			d:SetColor(Color.Aqua)
			d:SetDuration(0.1)
			debug.draw_line(center_of_rotation,self.m_interaction.click_offset,d)
			d:SetColor(Color.Red)
			debug.draw_line(center_of_rotation,r.origin + r.direction * t,d)

            local d = arm1:DotProduct(arm2);
            if (d > 0.999) then
            	orientation = start_orientation;
            	return orientation;
            end

            local angle = math.acos(d)
            if (angle < 0.001) then
            	orientation = start_orientation;
            	return orientation;
            end

           --[[ if (g.active_state.snap_rotation) then
                local snapped = make_rotation_quat_between_vectors_snapped(arm1, arm2, g.active_state.snap_rotation);
                orientation = qmul(snapped, start_orientation);
            else]]
                local a = arm1:Cross(arm2);
                a:Normalize()
                orientation = Quaternion(a, angle) *start_orientation;
            --end
        end
    end
    return orientation
end

local function flush_to_zero(f)
	if (math.abs(f.x) < 0.02) then f.x = 0.0 end
	if (math.abs(f.y) < 0.02) then f.y = 0.0 end
	if (math.abs(f.z) < 0.02) then f.z = 0.0 end
end

function Gizmo:AxisScaleDragger(id,g,axis,center,scale,uniform)
    -- interaction_state & interaction = g.gizmos[id];

    if (self.m_mouseLeft) then
        local plane_tangent = axis:Cross(center - self.m_camPosition);
        local plane_normal = axis:Cross(plane_tangent);

        local distance;
    	if (self.m_mouseLeft) then
            -- Define the plane to contain the original position of the object
            local plane_point = center;
            local ray = { origin = self.m_rayOrigin, direction = self.m_rayDirection };

            -- If an intersection exists between the ray and the plane, place the object at that point
            local denom = ray.direction:DotProduct(plane_normal);
            if (math.abs(denom) == 0) then return scale; end

            local t = (plane_point - ray.origin):DotProduct(plane_normal) / denom;

            if (t < 0) then return scale; end

            distance = ray.origin + ray.direction * t;
        end

        local offset_on_axis = (distance - self.m_interaction.click_offset) * axis;
        flush_to_zero(offset_on_axis);
        local new_scale = self.m_interaction.initial_pose:GetScale() + offset_on_axis;

        if (uniform) then
        	scale = math.clamp(distance:DotProduct(new_scale), 0.01, 1000.0);
        	scale = Vector(scale,scale,scale);
        else scale = Vector(math.clamp(new_scale.x, 0.01, 1000.0), math.clamp(new_scale.y, 0.01, 1000.0), math.clamp(new_scale.z, 0.01, 1000.0)); end
       -- if (g.active_state.snap_scale) then scale = snap(scale, g.active_state.snap_scale); end
    end
    return scale
end

function Gizmo:SetInteractionStart(start,interactionPos,initialPose)
	self.m_interactionStart = start or false
	self.m_interaction.click_offset = interactionPos or self.m_interaction.click_offset
	self.m_interaction.initial_pose = initialPose or self.m_interaction.initial_pose
end
function Gizmo:SetActive(active) self.m_mouseLeft = active end
function Gizmo:IsActive() return self.m_mouseLeft end

function Gizmo:SetRay(rayOrigin,rayDir)
	self.m_rayOrigin = rayOrigin
	self.m_rayDirection = rayDir
end

function Gizmo:SetCameraPosition(camPos) self.m_camPosition = camPos end
