class FlankPreviewFlagManager extends UIUnitFlagManager
    dependson(GotchaUnitFlagHelper);

const VISION_DISTANCE = 100000; //What are these units??
const HACKING_DISTANCE = 107500;

var array<UIUnitFlag>	flankedUnitsArr;
var UISpecialMissionHUD_Arrows ArrowManager;
var GotchaUnitFlagHelper unitFlagHelper;


function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local XComGameState_Unit SourceUnitState;

	ArrowManager = UISpecialMissionHUD_Arrows(`PRES.GetSpecialMissionHUD().GetChildByName('arrowContainer'));
    SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_lastActiveUnit.ObjectID,,-1));

//    `log("------------------");
//    `log("UNIT = " @ m_lastActiveUnit);

    // reset flankedArr to prevent a memory leak
	if (m_arrFlags.length == 0) {
	    flankedUnitsArr.length = 0;
	}

    processUnitsWithHealth(MoveToTileData, SourceUnitState);

    // Some objects do not have corresponding UnitFlag as they don't have health, so we need to search for them explicitly.
	processHackableObjectsWithoutHealth(MoveToTileData.EventTile, SourceUnitState);
}

private function processUnitsWithHealth(GameplayTileData MoveToTileData, XComGameState_Unit SourceUnitState)
{
    local int									Index;
    local UIUnitFlag							kFlag;
    local GameRulesCache_VisibilityInfo			VisibilityInfo;
    local XComGameState_Unit					TargetUnitState;
    local XComGameState_BaseObject				flagObj;
    local XComGameState_Destructible			destructibleObject;
    local XComGameState_InteractiveObject		interactiveObject;
    local T3DArrow								ObjArrow;
    local EUnitVisibilityState                  unitVState;
//    local vector                                testLocation;

    foreach m_arrFlags(kFlag)
    {
        if (kFlag.m_bIsFriendly) continue;

        flagObj = `XCOMHISTORY.GetGameStateForObjectID(kFlag.StoredObjectID,,-1);

//        `log("kFlag = " @ flagObj);

        TargetUnitState = XComGameState_Unit(flagObj);
        destructibleObject = XComGameState_Destructible(flagObj);
        interactiveObject = XComGameState_InteractiveObject(flagObj);


        // Interactive Objects
        if (interactiveObject != none)
        {
            ObjArrow = getArrowObject(class'GotchaUnitFlagHelper'.static.getUnitFlagLocation(kFlag));
//            `log("interactiveObject=" @ObjArrow.Icon);

            // can see via SquadSight
            if (`XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, interactiveObject.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
            {
                if (VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * VISION_DISTANCE))
                {
                    unitVState = eUVS_Spotted;
                }
                else
                {
                    unitVState = SourceUnitState.HasSquadSight() ? eUVS_SquadSight : eUVS_NotVisible;
                }
            }
            else
            {
                unitVState = eUVS_NotVisible;
            }

            SetUnitFlagState(kFlag, unitVState, ObjArrow);
            continue;
        }

        // Enemy Units
        if (TargetUnitState != none)
        {
            Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
            if (Index == INDEX_NONE) // if not visible
            {
                // can see via SquadSight
                if (SourceUnitState.HasSquadSight() && `XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, TargetUnitState.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
                {
                    displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo, true);
                }
                else
                {
                    SetUnitFlagState(kFlag, eUVS_NotVisible);
                }
            }
            else
            {
                VisibilityInfo = MoveToTileData.VisibleEnemies[Index];
                displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo, false);
            }
            continue;
        }

        // Destructible Objects (e.g. barrels)
        if (destructibleObject != none)
        {
//	        FindOrCreateVisualizer()

//	        `log("ActorName=" @destructibleObject.ActorId.ActorName @", destructibleObject.ActorId..Location=" @destructibleObject.ActorId.Location @", destructibleObject.TileLocation = (" @ destructibleObject.TileLocation.X @"," @ destructibleObject.TileLocation.Y @"," @ destructibleObject.TileLocation.Z);
//	        testLocation = `XWORLD.GetPositionFromTileCoordinates(destructibleObject.TileLocation);
//	        `log("testLocation = " @ testLocation);

            continue;
        }
    }
}

private function processHackableObjectsWithoutHealth(TTile eventTile, XComGameState_Unit SourceUnitState)
{
    local GameRulesCache_VisibilityInfo			VisibilityInfo;
    local XComGameState_Destructible			destructibleObject;
    local XComGameState_ObjectiveInfo           objectiveInfo;
    local XComInteractiveLevelActor             objActor;
    local XComGameState_InteractiveObject       actorObjectState;
    local StateObjectReference					EmptyRef;
    local T3DArrow								ObjArrow;
    local vector                                testLocation;

    // Mission: Recover Item from train
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ObjectiveInfo', objectiveInfo)
    {
        // skip objects that have been alredy processed by "WithHealth" processor
        destructibleObject = XComGameState_Destructible(`XCOMHISTORY.GetGameStateComponentForObjectID(objectiveInfo.ObjectID, class'XComGameState_Destructible'));
        if (destructibleObject == none || hasUnitFlag(destructibleObject.ObjectID)) continue;

        testLocation = `XWORLD.GetPositionFromTileCoordinates(destructibleObject.TileLocation);
        ObjArrow = getArrowObject(testLocation);
//        `log("HackableObjectWithoutHealth=" @ObjArrow.Icon);

        // display Hack icon obly if unit has IntrusionProtocol skill
        if (SourceUnitState.FindAbility('IntrusionProtocol') != EmptyRef)
        {
            `XWORLD.CanSeeTileToTile(eventTile, destructibleObject.TileLocation, VisibilityInfo);

            if (VisibilityInfo.bClearLOS && VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * HACKING_DISTANCE))
            {
                objActor = XComInteractiveLevelActor(objectiveInfo.GetVisualizer());
                actorObjectState = objActor.GetInteractiveState();

                if (actorObjectState.MustBeHacked() && !actorObjectState.HasBeenHacked())
                {
//                    `log("HACKING id=" @destructibleObject.ObjectID);
                    displayArrow(ObjArrow, eUVS_Hacking);
                    continue;
                }
            }
        }

        // clear arrow by default
        displayArrow(ObjArrow, eUVS_NotVisible);
    }
}

private function bool hasUnitFlag(int objectId)
{
    local UIUnitFlag kFlag;

    foreach m_arrFlags(kFlag)
    {
        if (kFlag.StoredObjectID == objectId) return true;
    }
    return false;
}

private function T3DArrow getArrowObject(vector vUnitLoc)
{
    local T3DArrow ObjArrow, ObjArrowNone;

    foreach ArrowManager.arr3Darrows(ObjArrow)
    {
//        `log("(" @ vUnitLoc.X @", " @vUnitLoc.Y @") => (" @ObjArrow.Loc.X @", " @ObjArrow.Loc.Y @"), icon=" @ ObjArrow.Icon);
        if (vUnitLoc.X == ObjArrow.Loc.X && vUnitLoc.Y == ObjArrow.Loc.Y)
        {
//            `log("FOUND, icon =" @ ObjArrow.icon);
            return ObjArrow;
        }
    }
    return ObjArrowNone;
}

private function displaySpottedIcon(UIUnitFlag kFlag,
                           TTile tile,
                           XComGameState_Unit SourceUnitState,
                           XComGameState_Unit TargetUnitState,
                           GameRulesCache_VisibilityInfo VisibilityInfo,
						   bool squadsight)
{
    local EUnitVisibilityState unitVState;
    local bool flanked;

    flanked = class'GotchaVisibilityHelper'.static.IsFlankedByLocation(tile, SourceUnitState, TargetUnitState, VisibilityInfo);

    // if flanked
    if (flanked && squadsight) unitVState = eUVS_SquadSightFlanked;
    if (flanked && !squadsight) unitVState = eUVS_Flanked;
    if (!flanked && squadsight) unitVState = eUVS_SquadSight;
    if (!flanked && !squadsight) unitVState = eUVS_Spotted;

    SetUnitFlagState(kFlag, unitVState);
}

private function SetUnitFlagState(UIUnitFlag kFlag,
                                  EUnitVisibilityState unitVState,
                                  optional T3DArrow ObjArrow)
{
    local vector vUnitLoc;
    local Vector2D vScreenLocation;
    
//    `log("SetUnitFlagState ::: kFlag = " @ kFlag.StoredObjectID @", unitVState=" @unitVState);

    SetSpottedAndFlankedState(kFlag, unitVState);

    // display Arrows only if specified.
    if (ObjArrow.icon != "")
    {
        // hide 
        vUnitLoc = class'GotchaUnitFlagHelper'.static.getUnitFlagLocation(kFlag);
        if (class'UIUtilities'.static.IsOnscreen(vUnitLoc, vScreenLocation))
        {
            unitVState = eUVS_NotVisible;
        }
        displayArrow(ObjArrow, unitVState);
    }
}

private function SetSpottedAndFlankedState(UIUnitFlag kFlag, EUnitVisibilityState unitVState)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local bool m_bFlanked;
	local bool spotted, flanked, squadsight;

	spotted = (unitVState == eUVS_Spotted || unitVState == eUVS_Flanked);
	flanked = (unitVState == eUVS_Flanked || unitVState == eUVS_SquadSightFlanked);
	squadsight = (unitVState == eUVS_SquadSight || unitVState == eUVS_SquadSightFlanked);

    // render flag only if it is a new state
    m_bFlanked = (flankedUnitsArr.find(kFlag) != INDEX_NONE);
	if (spotted == kFlag.m_bSpotted && flanked == m_bFlanked) return;

    // save the state
	kFlag.m_bSpotted = spotted;

	if (flanked) {
	    flankedUnitsArr.addItem(kFlag);
	} else {
	    flankedUnitsArr.removeItem(kFlag);
	}

    // Display crosshair
	myValue.Type = AS_Boolean;
	myValue.b = spotted;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
    myValue.b = flanked;
    myArray.AddItem( myValue );

	kFlag.Invoke("SetSpottedState", myArray);

	// Display squadsight diamond
    if (!squadsight) kFlag.SetAlertState(eUnitFlagAlert_None);
	else if (squadsight && !flanked)    kFlag.SetAlertState(eUnitFlagAlert_Red);
	else if (squadsight && flanked)    kFlag.SetAlertState(eUnitFlagAlert_Yellow);
}

private function displayArrow(T3DArrow ObjArrow, EUnitVisibilityState unitVState)
{
	local string arrowIcon;

//	`log("displayArrow ::: icon=" @ObjArrow.icon @", loc=" @ObjArrow.Loc @", unitVState=" @unitVState);

    // ignore invalid arrows. It should never happen but...
    if (ObjArrow.icon == "")
    {
//	    `log("INVALID arrow");
        return;
    }
	
    // calculate new icon based on the unit state
    arrowIcon = class'GotchaUnitFlagHelper'.static.getNewArrowIcon(ObjArrow.icon, unitVState);
//    `log("new arrowIcon=" @arrowIcon);

    // display arrow if icon is new
    if (arrowIcon != "" && arrowIcon != ObjArrow.icon)
    {
        ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, arrowIcon);
    }

}
