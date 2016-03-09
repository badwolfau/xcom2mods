class GotchaUnitFlagHelper extends Object;

enum EUnitVisibilityState
{
    eUVS_NotVisible,
    eUVS_Spotted,
    eUVS_Flanked,
    eUVS_SquadSight,
    eUVS_SquadSightFlanked,
    eUVS_Hacking
};

struct UnitArrowIconSet
{
	var string		defaultIcon;
	var string		spottedIcon;
	var string		flankedIcon;
	var string		squadsightIcon;
	var string		squadsightFlankedIcon;
	var string		hackingIcon;
};

//var array<UnitArrowIconSet> arrowIconSetArr;
var UnitArrowIconSet
        IconSet_Objective_DestroyAlienFacility,
        IconSet_Objective_HackWorkstation,
        IconSet_Objective_HackUFO,
        IconSet_Objective_Kill_VIP,
        IconSet_Objective_RecoverItem,
        IconSet_Objective_HackBroadcast;

defaultproperties
{
    // TODO: use array of icons instead of separate variables
    //    arrowIconSetArr = (
    //        (defaultIcon="img:///UILibrary_Common.Objective_DestroyAlienFacility", spottedIcon="img:///Gotcha.Objective_DestroyAlienFacility_spotted")
    //    );

    // Destroy alien transmitter
    IconSet_Objective_DestroyAlienFacility = {(
        defaultIcon = "img:///UILibrary_Common.Objective_DestroyAlienFacility",
        spottedIcon = "img:///Gotcha.Objective_DestroyAlienFacility_spotted",
        squadsightIcon = "img:///Gotcha.Objective_DestroyAlienFacility_squadsight",
    )};

    // Kill VIP
    IconSet_Objective_Kill_VIP = {(
        defaultIcon = "img:///UILibrary_Common.Objective_VIPBad",
        spottedIcon = "img:///Gotcha.Objective_VIPBad_spotted",
        flankedIcon = "img:///Gotcha.Objective_VIPBad_flanked",
        squadsightIcon = "img:///Gotcha.Objective_VIPBad_squadsight",
        squadsightFlankedIcon = "img:///Gotcha.Objective_VIPBad_squadsight_flanked",
    )};

    // Workstation hack
    IconSet_Objective_HackWorkstation = {(
        defaultIcon = "img:///UILibrary_Common.Objective_HackWorkstation",
        hackingIcon = "img:///Gotcha.Objective_HackWorkstation_hack",
    )};

    // Mission: Recover Item from train
    IconSet_Objective_RecoverItem = {(
        defaultIcon = "img:///UILibrary_Common.Objective_RecoverItem",
        hackingIcon = "img:///Gotcha.Objective_RecoverItem_hack",
    )};

    // Broadcast hack (second last mission)
    IconSet_Objective_HackBroadcast = {(
        defaultIcon = "img:///UILibrary_Common.Objective_Broadcast",
        hackingIcon = "img:///Gotcha.Objective_Broadcast_hack",
    )};

    // UFO hack
    IconSet_Objective_HackUFO = {(
        defaultIcon = "img:///UILibrary_Common.Objective_UFO",
        hackingIcon = "img:///Gotcha.Objective_UFO_hack",
    )};

}

//
static function string getNewArrowIcon(string currentIcon, EUnitVisibilityState unitVState)
{
    local UnitArrowIconSet arrowIconSet;

    arrowIconSet = getUnitArrowIconSet(currentIcon);
    if (arrowIconSet.defaultIcon == "") // if icon set not found
    {
        return currentIcon;
    }

    switch(unitVState)
    {
        case eUVS_Spotted:              return arrowIconSet.spottedIcon;
        case eUVS_Flanked:              return arrowIconSet.flankedIcon;
        case eUVS_SquadSight:           return arrowIconSet.squadsightIcon;
        case eUVS_SquadSightFlanked:    return arrowIconSet.squadsightFlankedIcon;
        case eUVS_Hacking:              return arrowIconSet.hackingIcon;
        default:
            return arrowIconSet.defaultIcon;
    }
}

static function UnitArrowIconSet getUnitArrowIconSet(string currentIcon)
{
    local UnitArrowIconSet arrowIconSet, arrowIconSetNone;
    local array<UnitArrowIconSet> arrowIconSetArr;

    // TODO: array should be static
    arrowIconSetArr.addItem(default.IconSet_Objective_DestroyAlienFacility);
    arrowIconSetArr.addItem(default.IconSet_Objective_HackWorkstation);
    arrowIconSetArr.addItem(default.IconSet_Objective_HackUFO);
    arrowIconSetArr.addItem(default.IconSet_Objective_Kill_VIP);
    arrowIconSetArr.addItem(default.IconSet_Objective_RecoverItem);
    arrowIconSetArr.addItem(default.IconSet_Objective_HackBroadcast);

    foreach arrowIconSetArr(arrowIconSet)
    {
        if (currentIcon == arrowIconSet.defaultIcon
            || currentIcon == arrowIconSet.spottedIcon
            || currentIcon == arrowIconSet.flankedIcon
            || currentIcon == arrowIconSet.squadsightIcon
            || currentIcon == arrowIconSet.squadsightFlankedIcon
            || currentIcon == arrowIconSet.hackingIcon )
        {
            return arrowIconSet;
        }
    }
    return arrowIconSetNone;
}

// extract unit location from UnitFlag
static function vector getUnitFlagLocation(UIUnitFlag kFlag)
{
    local vector vUnitLoc;
    local X2VisualizerInterface VisualizedInterface;
    local Actor VisualizedActor;

    // Now get the unit's location data
    VisualizedActor = `XCOMHISTORY.GetVisualizer(kFlag.StoredObjectID);
    VisualizedInterface = X2VisualizerInterface(VisualizedActor);
    if (VisualizedInterface != none)
    {
        vUnitLoc = VisualizedInterface.GetUnitFlagLocation();
    }
    else
    {
        vUnitLoc = VisualizedActor.Location;
    }

    return vUnitLoc;
}