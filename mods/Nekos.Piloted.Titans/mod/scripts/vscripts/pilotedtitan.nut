global function pilotedtitan_init

struct
{
array<entity> props
table<entity, entity> propsowner
table<entity, entity> playersprop
table<entity, bool> isntbeingexecuted
table<entity, bool> isntexecuting
table<entity, bool> hasntplayedbossintro
table<entity, bool> iscontrolledbynpc
}file

void function pilotedtitan_init()
{
Pilotedtitan()
AddCallback_OnPilotBecomesTitan( OnPilotBecomesTitan )
AddCallback_OnTitanBecomesPilot( OnTitanBecomesPilot )
AddSpawnCallback( "npc_titan", OnNPCTitanSpawned )
PrecacheModel( $"models/humans/pilots/sp_medium_reaper_m.mdl" )
}

entity function CreateCockpitPilot( entity player, asset model )
{
entity prop = CreateEntity( "npc_pilot_elite" ) // Would Use CreatePropDynamic But Its Buggy Trying To Look In The Cockpit
prop.SetOrigin( player.GetOrigin() )
prop.SetModel( model )
SetTeam( prop, player.GetTeam() )
prop.SetInvulnerable()
SetSpawnOption_Weapon( prop, "mp_weapon_lmg" )
DispatchSpawn( prop )
prop.kv.VisibilityFlags = ~ENTITY_VISIBLE_TO_EVERYONE
NPC_NoTarget( prop )
prop.EnableNPCFlag( NPC_IGNORE_ALL )
prop.SetModel( model )
SetTeam( prop, player.GetTeam() )
prop.SetInvulnerable()
HideName( prop )
return prop
}

void function OnNPCTitanSpawned( entity titan )
{
thread ExecutionCheck( titan )
if( !IsSingleplayer() )
thread OnNPCTitanSpawned_mp( titan )
 if( IsSingleplayer() )
 {
 thread OnNPCTitanSpawned_sp( titan )
 if( GetMapName() != "sp_s2s" )
 thread TitanBossIntroCheck_sp( titan )
 }
}

void function ExecutionCheck( entity titan )
{
titan.EndSignal( "OnDestroy" )
titan.EndSignal( "OnDeath" )
titan.EndSignal( "OnSyncedMeleeVictim" )
OnThreadEnd(
	function() : ( titan )
	{
     if( IsValid( titan ) )
     {
      if( IsAlive( titan ) )
      file.isntbeingexecuted[titan] <- false
     }
	}
)
 while( true )
 {
 titan.WaitSignal( "OnSyncedMeleeAttacker" )
 file.isntexecuting[titan] <- false
 WaittillAnimDone( titan )
 file.isntexecuting[titan] <- true
 }
}

void function TitanBossIntroCheck_sp( entity titan )
{
titan.EndSignal( "OnDestroy" )
titan.EndSignal( "OnDeath" )
 while( true )
 {
  WaitFrame()
  if( titan.e.isHotDropping == false && titan.Anim_IsActive() )
  {
  wait 0.2
  WaittillAnimDone( titan )
  file.hasntplayedbossintro[titan] <- false
  return
  }
 }
}

bool function IsValidForPilotSpawn( entity titan )
{
bool valid = true
if ( titan in file.isntexecuting )
valid = file.isntexecuting[titan]
if ( titan in file.isntbeingexecuted && valid != false )
valid = file.isntbeingexecuted[titan]
 if ( IsSingleplayer() && GetMapName() != "sp_s2s" ) // Viper Never Shows Their Pilot
 {
 bool hasntplayedbossintro = true
 if ( titan in file.hasntplayedbossintro )
 hasntplayedbossintro = file.hasntplayedbossintro[titan]
 if( hasntplayedbossintro == true )
 valid = false
 }
return valid
}

bool function IsEliteTitan( entity titan )
{
	if ( titan.GetTeam() != TEAM_IMC )
		return false

	switch ( titan.ai.bossTitanType )
	{
		case TITAN_MERC:
		case TITAN_BOSS:
			return true
	}

	return false
}

void function OnNPCTitanSpawned_mp( entity titan )
{
 titan.EndSignal( "OnDestroy" )
 titan.EndSignal( "OnDeath" )
 entity soul = titan.GetTitanSoul()
 if( !IsValid( soul ) )
 return
 soul.EndSignal( "OnDestroy" )
 while( true )
 {
  if( soul.soul.seatedNpcPilot.isValid )
  {
   if( soul.soul.seatedNpcPilot.modelAsset != $"" )
   {
    entity playersprop
    if ( titan in file.playersprop )
    {
    playersprop = file.playersprop[titan]
    }
    if( !IsValid( playersprop ) && IsValidForPilotSpawn( titan ) )
    {
    //entity prop = CreatePropDynamic( soul.soul.seatedNpcPilot.modelAsset )
    entity prop = CreateCockpitPilot( titan, soul.soul.seatedNpcPilot.modelAsset )
    file.iscontrolledbynpc[titan] <- true
    file.playersprop[titan] <- prop
    file.propsowner[prop] <- titan
    file.props.append( prop )
    }
   }
  }
  if( IsEliteTitan( titan ) )
  {
   if( GameRules_GetGameMode() == FD )
   {
    entity playersprop
    if ( titan in file.playersprop )
    {
    playersprop = file.playersprop[titan]
    }
    if( !IsValid( playersprop ) && IsValidForPilotSpawn( titan ) )
    {
    //entity prop = CreatePropDynamic( TEAM_IMC_GRUNT_MODEL )
    entity prop = CreateCockpitPilot( titan, TEAM_IMC_GRUNT_MODEL )
    file.playersprop[titan] <- prop
    file.propsowner[prop] <- titan
    file.props.append( prop )
    }
   }
  }
  WaitFrame()
 }
}

void function OnNPCTitanSpawned_sp( entity titan )
{
 titan.EndSignal( "OnDestroy" )
 titan.EndSignal( "OnDeath" )
 entity soul = titan.GetTitanSoul()
 if( !IsValid( soul ) )
 return
 soul.EndSignal( "OnDestroy" )
 while( true )
 {
  #if HAS_BOSS_AI
  if ( IsBossTitan( titan ) )
  {
   entity playersprop
   if ( titan in file.playersprop )
   {
   playersprop = file.playersprop[titan]
   }
   if( !IsValid( playersprop ) && IsValidForPilotSpawn( titan ) )
   {
   //entity prop = CreatePropDynamic( GetBossTitanCharacterModel( titan ) )
   entity prop = CreateCockpitPilot( titan, GetBossTitanCharacterModel( titan ) )
   file.playersprop[titan] <- prop
   file.propsowner[prop] <- titan
   file.props.append( prop )
   }
  }
  #endif
  WaitFrame()
 }
}

void function OnTitanBecomesPilot( entity pilot, entity titan )
{
entity playersprop
if ( pilot in file.playersprop )
playersprop = file.playersprop[pilot]
if( IsValid( playersprop ) )
playersprop.Destroy()
}

void function OnPilotBecomesTitan( entity pilot, entity titan )
{
thread OnPilotBecomesTitan_thread( pilot )
}

void function OnPilotBecomesTitan_thread( entity pilot )
{
pilot.EndSignal( "OnDestroy" )
pilot.EndSignal( "OnDeath" )
 while( true )
 {
  if( !pilot.IsTitan() )
  return
  if( pilot.IsTitan() )
  {
   entity playersprop
   if ( pilot in file.playersprop )
   {
   playersprop = file.playersprop[pilot]
   }
   if( !IsValid( playersprop ) && !pilot.ContextAction_IsMeleeExecution() )
   {
   entity model = Wallrun_CreateCopyOfPilotModel( pilot )
   //entity prop = CreatePropDynamic( model.GetModelName() )
   entity prop = CreateCockpitPilot( pilot, model.GetModelName() )
   file.playersprop[pilot] <- prop
   file.propsowner[prop] <- pilot
   file.props.append( prop )
   model.Destroy()
   }
  }
  WaitFrame()
 }
}

void function Pilotedtitan()
{
thread Pilotedtitan_thread()
}

void function Pilotedtitan_thread()
{
 while( true )
 {
  foreach( entity prop in file.props )
  {
   if( IsValid( prop ) )
   {
    entity propsowner
    if ( prop in file.propsowner )
    propsowner = file.propsowner[prop]
    if( !IsValid( propsowner ) )
    prop.Destroy()
    if( IsValid( prop ) )
    {
    if( !IsAlive( propsowner ) )
    prop.Destroy()
    }
    if( IsValid( prop ) )
    {
    if( propsowner.ContextAction_IsMeleeExecution() )
    prop.Destroy()
    }
    if( IsValid( prop ) )
    {
     if( !propsowner.IsPlayer() )
     {
      if( !IsValidForPilotSpawn( propsowner ) ) 
      prop.Destroy()
     }
    }
    if( IsValid( prop ) )
    {
     if( !propsowner.IsPlayer() )
     {
      entity soul = propsowner.GetTitanSoul()
      if( IsValid( soul ) )
      {
       bool iscontrolledbynpc = false
       if ( propsowner in file.iscontrolledbynpc )
       iscontrolledbynpc = file.iscontrolledbynpc[propsowner]
       if( iscontrolledbynpc == true )
       {
       if( !( soul.soul.seatedNpcPilot.isValid ) )
       prop.Destroy()
       }
      }
     }
    }
    if( IsValid( prop ) )
    {
     if( prop.GetTeam() != propsowner.GetTeam() )
     SetTeam( prop, propsowner.GetTeam() )
     FirstPersonSequenceStruct sequence
     sequence.attachment = "hijack"
     sequence.useAnimatedRefAttachment = true
     sequence.blendTime = 0
     sequence.thirdPersonAnim = "pt_mt_synced_bt_execute_kickshoot_V"
	 string attackerType = GetTitanCharacterName( propsowner )
	 switch ( attackerType )
     {
	 case "scorch":
 	 case "legion":
     sequence.thirdPersonAnim = "pt_mount_ogre_kneel_behind"
     sequence.setInitialTime = 2.5
     break
     }
     thread FirstPersonSequence( sequence, prop, propsowner )
     prop.kv.VisibilityFlags = propsowner.kv.VisibilityFlags
    }
   }
  }
  WaitFrame()
 }
}