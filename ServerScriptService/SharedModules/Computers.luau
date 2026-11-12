





local Computers = {
	["Weapon"]="Weapon",
	["OffHand"]="OffHand",
	["Ammo"]="Ammo",
	["Tool"]="Tool",
	["Clothing"]="Clothing",
	["Misc"]="Misc",
	["PowerSource"]="PowerSource",
	["Heal"]="Heal",
	["Trash"]="Trash",
	["Consumable"]="Consumable",
	["Material"]="Material",
	["TempHold"]="TempHold",
	["Money"]="Money"

}



local module = {


	["1111"] = {
		["ComputerName"]="Sci Co Network",
		["ComputerNumber"]="1111",
		["0"] = "Sci Co Network\n1) Account\n2) Records\n3) Security\n4) Open Disk\nq) Exit",
		
		["1"] = "Account\n11) Timesheets\n12) Schedule\n0) Main Menu",
		["11"] = "Timesheets\n8:00AM Turned on Worker Bot\n 9:00AM Fiddled with jammed desk drawer \n 10:00AM Filled out Timesheet  \n0) Main Menu",
		["12"] = "Schedule\n 11:00AM Meeting - How to keep motivated\n 12:00PM Lunch \n 1:00PM Meeting - Motivation on a full stomach \n0) Main Menu",

		["2"] = "Records\n21) Users \n22) Download Star Chart \n23) Top Secret Projects \n0) Main Menu",

		["21"] = {Command="ListUsers"},
		["22"] = "Enter Star Chart ID:",
		["23"]="Authorized Personel Only",
		
		["3"]="Enter Password:",
		
		["4562"]= "Security\n991) Remote Locks\n992) Security Cameras\n0 Main Menu",
		["991"]="Security: Remote Locks\n9911) Toggle Escape Pod Room Door\n9912) Toggle Supply Room Door",
		["992"]="Security: Security Cameras\n9921) Toggle Camera 1\n9922) Toggle Camera 2",

		["9911"]={Command="ToggleLock",LockName="EscapePodRoom"},
		["9912"]={Command="ToggleLock",LockName="SupplyRoom"},
		["9921"]={Command="ToggleCamera",Camera="Cam1"},
		["9922"]={Command="ToggleCamera",Camera="Cam2"},

		["4"]="Enter Name of Disk",
		--["5"]="Enter Remote Computer Number",
		--["5643"]="[SetComputer5643]",



	};

	["5643"] = {
		["ComputerName"]="Home Computer",
		["ComputerNumber"]="5643",
		["0"] = "Hello [Player Name]\n1. Calculator\n2. Games\n3. Open Disk\n4. Dial Modem\nq. Exit",
		--TODO add handling of all of these



	};
	
	["9245"] = {
		["ComputerName"]="Sci Co Network",
		["ComputerNumber"]="9245",
		["0"] = "Hello Professor\n1.List Games\nq. Exit",
		["1"] = "Games\n11.What Card Am I Holding\n12.Global Thermonuclear War\nq. Exit",
		--TODO add handling of all of these



	};
}

return module
