# SimpleHitbox
Create simple box shaped hitboxes for humanoid detection.

# API Document
### Properties
> * module.VISUALIZE_HITBOX: boolean (client-only)
> if true, server will tell the client to visualize the hitbox

### Functions
> * module.new: (part: BasePart, offset: CFrame, size: Vector3, interval: number, overlapParams: OverlapParams) -> ({Connection: RBXScriptConnection, HumanoidDetected: RBXScriptSignal})

# Roblox Marketplace
https://create.roblox.com/marketplace/asset/15117466504/SimpleHitbox

# Example Script
```lua
local offset = CFrame.new(0, 0, -3)
local size = Vector3.new(3, 6, 3)
local hitbox = module.new(character.HumanoidRootPart, offset, size, 0.15)

hitbox.HumanoidDetected:Connect(function(humanoid)
	humanoid:TakeDamage(10)
end)

task.wait(1)

hitbox.Connection:Disconnect()
```
