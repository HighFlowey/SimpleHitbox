--// Services
local RunService = game:GetService("RunService")

--[[

	-- Example Code --

	local offset = CFrame.new(0, 0, -3)
	local size = Vector3.new(3, 6, 3)
	local hitbox = module.new(humanoidRootPart, offset, size, 0.15)

	hitbox.HumanoidDetected:Connect(function(humanoid)
		humanoid:TakeDamage(10)
	end)

	task.wait(1)

	hitbox.Connection:Disconnect()
	
	-- Example Code --
	
]]

--// Configs
local HITBOX_VISUALIZER = Instance.new("Part")
HITBOX_VISUALIZER.Anchored = true
HITBOX_VISUALIZER.CanCollide = false
HITBOX_VISUALIZER.CanQuery = false
HITBOX_VISUALIZER.CanTouch = false
HITBOX_VISUALIZER.Transparency = 0.75
HITBOX_VISUALIZER.Material = Enum.Material.Neon
HITBOX_VISUALIZER.Color = Color3.new(1, 0, 0)

--// Modules
local Signal = require(script:WaitForChild("Packages"):WaitForChild("signal"))
local BridgeNet2 = require(script:WaitForChild("Packages"):WaitForChild("bridgenet2"))
local PartCache = require(script:WaitForChild("partcache"))
local Squash = require(script:WaitForChild("Packages"):WaitForChild("squash"))

--// Variables
local partCache = PartCache.new(HITBOX_VISUALIZER, 150)
local bridge = BridgeNet2.ReferenceBridge("Hitbox")
local bridgeActions = {
	Visualize = 0,
}

local module = {}
module.VISUALIZE_HITBOX = true

local replicating = {} -- players that want hitbox to be visualized
local proxy: typeof(module) = newproxy(true)
local meta = getmetatable(proxy)
meta.__index = module
meta.__newindex = function(_, i, v)
	if module[i] == v then return end
	
	if RunService:IsClient() and i == "VISUALIZE_HITBOX" then
		bridge:Fire({bridgeActions.Visualize, v})
	end
	
	module[i] = v
end

--// Functions
--[[

	@ module.new()

	-- Arguments:
		part: BasePart,
		offset: CFrame,
		size: Vector3,
		interval: number,
		overlapParams: OverlapParams,
	
	-- Returns:
		{
			Connection: RBXScriptConnection,
			HumanoidDetected: RBXScriptSignal,
		}

]]
function module.new(part: BasePart, offset: CFrame, size: Vector3, interval: number, overlapParams: OverlapParams)
	local connection: RBXScriptConnection -- connection of hitbox loop
	local last_hitbox_made = 0 -- last time we made a hitbox
	
	local humanoids = {} -- list of detected humanoids
	local detected = Signal.new() -- fire this event when you detect a new humanoid
	
	connection = RunService.Heartbeat:Connect(function()
		-- Make a hitbox every "intervals" seconds
		if time() - last_hitbox_made > interval then
			local cframe = part.CFrame*offset
			local parts = workspace:GetPartBoundsInBox(cframe, size, overlapParams)
			
			-- Tell clients to visualize the hitbox using a part
			bridge:Fire(BridgeNet2.Players(replicating), {
				bridgeActions.Visualize,
				Squash.CFrame.ser(cframe),
				Squash.Vector3.ser(size),
			})
			
			for _, v in parts do
				-- Check all parts to find their humanoids
				local character = v.Parent
				local humanoid = character:FindFirstChildWhichIsA("Humanoid")
				
				if humanoid and not humanoids[humanoid] then
					-- Fire detected event for humanoid
					detected:Fire(humanoid)
					humanoids[humanoid] = true
				end
			end
			
			last_hitbox_made = time()
		end
	end)
	
	return {
		-- return the connection so we can :Disconnect() it anytime we want
		Connection = connection,
		-- return the detected event so we can use :Connect on it when we detect a humanoid
		HumanoidDetected = detected,
	}
end

if RunService:IsServer() then
	-- Server only code
	bridge:Connect(function(player, content)
		local action = content[1]
		
		if action == bridgeActions.Visualize  then
			local boolean = table.unpack(content, 2)
			local exists = table.find(replicating, player)

			if boolean ~= true and exists then
				table.remove(replicating, exists)
			elseif boolean == true and not exists then
				table.insert(replicating, player)
			end
		end
	end)
else
	-- Client only code
	bridge:Fire({bridgeActions.Visualize ,module.VISUALIZE_HITBOX})
	bridge:Connect(function(content)
		local action = content[1]
		
		if action == bridgeActions.Visualize then
			local serializedCFrame, serializedSize = table.unpack(content, 2)
			local cframe, size = Squash.CFrame.des(serializedCFrame), Squash.Vector3.des(serializedSize)

			local part = partCache:GetPart()
			part.CFrame = cframe
			part.Size = size
			part.Parent = workspace

			task.delay(0.75, function()
				partCache:ReturnPart(part)
			end)
		end
	end)
end

return proxy
