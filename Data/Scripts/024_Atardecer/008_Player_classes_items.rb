################################################################################
# Item handlers
################################################################################

# ARISTOCRATA

ItemHandlers.addUseInField(:LUXURYCATALOG, proc {
   next pbCommonEvent(3)
})

ItemHandlers.addUseFromBag(:LUXURYCATALOG, proc {
   next pbCommonEvent(3)
})

# ARQUEOLOGA

ItemHandlers.addUseInField(:MININGKIT, proc {
   next pbCommonEvent(4)
})

ItemHandlers.addUseFromBag(:MININGKIT, proc {
   next pbCommonEvent(4)
})