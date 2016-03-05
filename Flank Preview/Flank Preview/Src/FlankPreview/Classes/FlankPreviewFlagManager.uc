class FlankPreviewFlagManager extends UIUnitFlagManager
    dependson(GotchaUnitFlagHelper);

const VISION_DISTANCE = 100000; //What are these units??
const HACKING_DISTANCE = 107500;

var array<UIUnitFlag>	flankedUnitsArr;
var UISpecialMissionHUD_Arrows ArrowManager;
var GotchaUnitFlagHelper unitFlagHelper;


function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local int									Index;
	local UIUnitFlag							kFlag;
	local GameRulesCache_VisibilityInfo			VisibilityInfo;
	local XComGameState_Unit					SourceUnitState, TargetUnitState;
	local XComGameState_BaseObject				flagObj;
	local XComGameState_Destructible			destructibleObject;
	local XComGameState_InteractiveObject		interactiveObject;

	local T3DArrow								ObjArrow;
//	local StateObjectReference					EmptyRef;
    local EUnitVisibilityState unitVState;
    local vector testLocation;


	ArrowManager = UISpecialMissionHUD_Arrows(`PRES.GetSpecialMissionHUD().GetChildByName('arrowContainer'));
    SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_lastActiveUnit.ObjectID,,-1));

    `log("------------------");
    `log("UNIT = " @ m_lastActiveUnit);

    // reset flankedArr to prevent a memory leak
	if (m_arrFlags.length == 0) {
	    flankedUnitsArr.length = 0;
	}

	foreach m_arrFlags(kFlag)
	{
	    if (kFlag.m_bIsFriendly) continue;


	    flagObj = `XCOMHISTORY.GetGameStateForObjectID(kFlag.StoredObjectID,,-1);
	    ObjArrow = getArrowObject(kFlag);

	    `log("kFlag = " @ flagObj @", arrow=" @ObjArrow.Icon);

	    TargetUnitState = XComGameState_Unit(flagObj);
	    destructibleObject = XComGameState_Destructible(flagObj);
	    interactiveObject = XComGameState_InteractiveObject(flagObj);


        // Interactive Objects
        if (interactiveObject != none) {
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

            SetUnitState(kFlag, unitVState, ObjArrow);
            continue;
        }

        // Enemy Units
	    if (TargetUnitState != none) {
	        Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
	        if (Index == INDEX_NONE) // if not visible
            {
                // can see via SquadSight
                if (SourceUnitState.HasSquadSight() && `XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, TargetUnitState.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
                {
                    displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo, true, ObjArrow);
                }
                else
                {
                    SetUnitState(kFlag, eUVS_NotVisible, ObjArrow);
                }
            }
            else
            {
                VisibilityInfo = MoveToTileData.VisibleEnemies[Index];
                displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo, false, ObjArrow);
            }
            continue;
	    }

        // Destructible Objects (e.g. barrels)
        // Missions: Recover Item from train
	    if (destructibleObject != none) {
	        `log("destructibleObject.ActorId..Location=" @destructibleObject.ActorId.Location @", destructibleObject.TileLocation = (" @ destructibleObject.TileLocation.X @"," @ destructibleObject.TileLocation.Y @"," @ destructibleObject.TileLocation.Z);
	        testLocation = `XWORLD.GetPositionFromTileCoordinates(destructibleObject.TileLocation);
	        `log("testLocation = " @ testLocation);
//	        if(SourceUnitState.FindAbility('IntrusionProtocol') != EmptyRef)
//            if(`XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, ArrowTile, VisibilityInfo) && VisibilityInfo.bClearLOS && VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * HACKING_DISTANCE))

//            objActor = XComInteractiveLevelActor(objectiveInfo.GetVisualizer());
//            actorObjectState = objActor.GetInteractiveState();
//          if(actorObjectState.MustBeHacked() && !actorObjectState.HasBeenHacked())

            // TODO: test call
	        SetUnitState(kFlag, eUVS_Spotted, ObjArrow);
	        continue;
        }

	}
}

private function T3DArrow getArrowObject(UIUnitFlag kFlag)
{
    local vector vUnitLoc;
    local T3DArrow ObjArrow, ObjArrowNone;

    vUnitLoc = class'GotchaUnitFlagHelper'.static.getUnitFlagLocation(kFlag);

    foreach ArrowManager.arr3Darrows(ObjArrow)
    {
        `log("(" @ vUnitLoc.X @", " @vUnitLoc.Y @") => (" @ObjArrow.Loc.X @", " @ObjArrow.Loc.Y @"), icon=" @ ObjArrow.Icon);
        if (vUnitLoc.X == ObjArrow.Loc.X && vUnitLoc.Y == ObjArrow.Loc.Y)
        {
            `log("FOUND, icon=" @ ObjArrow.icon);
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
						   bool squadsight,
						   T3DArrow ObjArrow)
{
    local EUnitVisibilityState unitVState;
    local bool flanked;

    flanked = class'GotchaVisibilityHelper'.static.IsFlankedByLocation(tile, SourceUnitState, TargetUnitState, VisibilityInfo);

    // if flanked
    if (flanked && squadsight) unitVState = eUVS_SquadSightFlanked;
    if (flanked && !squadsight) unitVState = eUVS_Flanked;
    if (!flanked && squadsight) unitVState = eUVS_SquadSight;
    if (!flanked && !squadsight) unitVState = eUVS_Spotted;

    SetUnitState(kFlag, unitVState, ObjArrow);
}

private function SetUnitState(UIUnitFlag kFlag, EUnitVisibilityState unitVState, T3DArrow ObjArrow)
{
    `log("kFlag = " @ kFlag.StoredObjectID @", unitVState=" @unitVState @", icon=" @ObjArrow.icon);
    SetSpottedAndFlankedState(kFlag, unitVState);
    updateArrowState(kFlag, unitVState, ObjArrow);
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

private function updateArrowState(UIUnitFlag kFlag, EUnitVisibilityState unitVState, T3DArrow ObjArrow)
{
	local string arrowIcon;
	local vector vUnitLoc;
	local Vector2D vScreenLocation;

	// Display Arrow
	if (ObjArrow.icon != "") {

	    vUnitLoc = class'GotchaUnitFlagHelper'.static.getUnitFlagLocation(kFlag);
        if (class'UIUtilities'.static.IsOnscreen(vUnitLoc, vScreenLocation))
        {
            unitVState = eUVS_NotVisible;
        }

        // calculate new icon based on the unit state
        arrowIcon = class'GotchaUnitFlagHelper'.static.getNewArrowIcon(ObjArrow.icon, unitVState);

        // display arrow if icon is new
        if (arrowIcon != "" && arrowIcon != ObjArrow.icon)
        {
            ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, arrowIcon);
        }
    }

}
