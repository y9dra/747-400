--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
local clock = os.clock
function sleep(n)
  local t0 = clock()
  while clock() - t0 <= n do end
end

function fmsFunctions.initAcars(fmsO,value)
  local currentInit=getFMSData("acarsInitString")
  local initData={}
  initData["reg"]=getFMSData("fltno")
  if initData["reg"]=="*******" then fmsO["notify"]="FLT NO NOT SET" return end
  initData["dep"]=getFMSData("fltdep")
  if initData["dep"]=="****" then fmsO["notify"]="DEPARTURE NOT SET" return end
  initData["dst"]=getFMSData("fltdst")
  if initData["dst"]=="****" then fmsO["notify"]="DESTINATION NOT SET" return end
  initData["crzalt"]=getFMSData("crzalt")
  
  local newInit=json.encode(initData)
  if currentInit~= newInit then
    fmsModules["data"]["acarsInitString"]=newInit
    initData["type"]="initData"
    initData["af"]="B744"
    local newInitSend=json.encode(initData)
    print(newInitSend)
    fmsFunctions.acarsSystemSend(fmsO,newInitSend)
  end
  fmsO["pgNo"]=1
  fmsO["targetCustomFMC"]=true
  fmsO["targetPage"]="PREFLIGHT"
  run_after_time(switchCustomMode, 0.5)
end
function fmsFunctions.acarsLogonATC(fmsO,value)
  if getFMSData("fltno")=="*******" then fmsO["notify"]="FLT NO NOT SET" return end
  if getFMSData("fltdep")=="****" then fmsO["notify"]="DEPARTURE NOT SET" return end
  if getFMSData("fltdst")=="****" then fmsO["notify"]="DESTINATION NOT SET" return end
  acarsSystem.provider.logoff()
  local atcLogon={}
  setFMSData("atc",value)
  if fmsModules["data"]["atc"]=="****" then return end
	atcLogon["type"]="cpdlc"
  atcLogon["msg"]="REQUEST LOGON"
  local newInitSend=json.encode(atcLogon)
  fmsFunctions.acarsSystemSendATC(fmsO,newInitSend)
end
function fmsFunctions.acarsATCRequest(fmsO,value)
  local atcReq={}
	atcReq["type"]="inforeq"
  atcReq["msg"]=value
  local newInitSend=json.encode(atcReq)
  fmsFunctions.acarsSystemSendATC(fmsO,newInitSend)
end
fmsPages["ACARSMSGS"]=createPage("ACARSMSGS")
fmsPages["ACARSMSGS"]["template"]={

"    ACARS-MSGS MENU     ",
"                        ",
"<FLT DSPTCH        MISC>",
"                        ",
"<UPLINK           DNLNK>",
"                        ",
"<PRINT UNDELIVERED MSGS ",
"                        ",
"                        ",
"                        ",
"                        ", 
"                        ",
"<RETURN                 "
}
fmsPages["ACARSMSGS"]["templateSmall"]={
"                        ",
"--------SEND MSG--------",
"                        ",
"-------STORED MSG-------",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ", 
"                        ",
"                        "
}
fmsFunctionsDefs["ACARSMSGS"]["L2"]={"setpage","VIEWUPACARS"}
fmsFunctionsDefs["ACARSMSGS"]["L6"]={"setpage","ACARS"} --go to last page or acars
fmsFunctionsDefs["ACARSMSGS"]["R1"]={"setpage","VIEWMISCACARS"}

fmsFunctionsDefs["ACARSMSGS"]["L6"]={"setpage","ACARS"}

fmsPages["VIEWMISCACARS"]=createPage("VIEWMISCACARS")

acarsSystem={}
acarsSystem.messages={}
acarsSystem.messageSendQueue={}
acarsSystem.sentMessage=0
--print("have this many "..table.getn(acarsSystem.messages.values).." acars messages")
dofile("acars/autoatcProvider.lua")

function fmsFunctions.acarsSystemSend(fmsO,value)
  if acarsSystem.provider.online() then
    local msgToSend=value
    local tMSG={}
    if string.len(msgToSend) <5 then 
      tMSG["adr"]=getFMSData("acarsAddress")
       if tMSG["adr"]=="*******" then fmsO["notify"]="EMPTY ADDRESS" return end
      msgToSend=fmsO["scratchpad"]
      tMSG["type"]="cpdlc"
      tMSG["msg"]=msgToSend
      fmsO["scratchpad"]=""
    else
      tMSG=json.decode(value)
    end
    if string.len(msgToSend) <5 then fmsO["notify"]="EMPTY MESSAGE" return end
    
    
    acarsSystem.provider.sendCompany(json.encode(tMSG))
    fmsO["targetCustomFMC"]=true
    run_after_time(switchCustomMode, 0.5)
    --fmsO["currentPage"]="ACARS" 
    --local tMSG=json.encode({type="msg",msg="Test Message",time="12:00 UTC"})
    --print(tMSG)
    --local rMSG=json.decode(tMSG)
    --print(rMSG["msg"])
  else
    fmsO["notify"]="ACARS NO COMM" 
  end
  --print("setpage" .. value)
end
function fmsFunctions.acarsSystemSendATC(fmsO,value)

  if acarsSystem.provider.online() then
    local msgToSend=value
    local tMSG={}
    if string.len(msgToSend) <5 then 
      tMSG["to"]=getFMSData("acarsAddress")
       if tMSG["to"]=="*******" then fmsO["notify"]="EMPTY ADDRESS" return end
      msgToSend=fmsO["scratchpad"] 
      tMSG["type"]="cpdlc"
      tMSG["msg"]=msgToSend
      fmsO["scratchpad"]=""
    else
      tMSG=json.decode(value)
    end
    if string.len(msgToSend) <5 then fmsO["notify"]="EMPTY MESSAGE" return end
    acarsSystem.provider.sendATC(json.encode(tMSG))
    fmsO["targetCustomFMC"]=true
    run_after_time(switchCustomMode, 0.5)
    --fmsO["currentPage"]="ACARS" 
    --local tMSG=json.encode({type="msg",msg="Test Message",time="12:00 UTC"})
    --print(tMSG)
    --local rMSG=json.decode(tMSG)
    --print(rMSG["msg"])
  else
    fmsO["notify"]="ACARS NO COMM" 
  end
  --print("setpage" .. value)
end


acarsSystem.getMiscMessages=function(pgNo)
    

     
    retVal={}
    retVal.template={
      "   ACARS-MISC MSGS      ",
      "                        ",
      "                        ", -- --"<Test Message           ",
      "                        ",
      "                        ", -- --"<2nd Test Message       ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      " ADDRESS                ",
      "<"..fmsModules["data"]["acarsAddress"] .."           SEND>",
      "                        ",
      "<RETURN                 "
      } 
      numPages=math.ceil(table.getn(acarsSystem.messages.values)/4)
      if numPages<1 then numPages=1 end
    retVal.templateSmall={
      "                     "..pgNo.."/"..numPages.." ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        "
      }
    line = 3
    startNo=table.getn(acarsSystem.messages.values)
    
    if pgNo>1 then startNo=table.getn(acarsSystem.messages.values)-((pgNo-1)*4) end
    endNo=startNo-3
    if endNo <1 then endNo=1 end
    for i = startNo,endNo , -1 do
      retVal.template[line]="<"..acarsSystem.messages[i]["title"]
      --if not acarsSystem.messages[i]["read"] then
	--retVal.template[line]=retVal.template[line].." (new)"
      --end
      retVal.templateSmall[line+1]="            "..acarsSystem.messages[i]["time"]
      fmsFunctionsDefs["VIEWMISCACARS"]["L"..(startNo-i+1)]={"showmessage",i}
      line = line+2
      
    end  
    return retVal
end

fmsPages["VIEWUPACARS"]=createPage("VIEWUPACARS")



acarsSystem.getUpMessages=function(pgNo)
    retVal={}
    retVal.template={
      "  ACARS-UPLINK MSG      ",
      "                        ",
      "                        ", -- --"<Test Message           ",
      "                        ",
      "                        ", -- --"<2nd Test Message       ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "<RETURN                 "
      } 
      numPages=math.ceil(table.getn(acarsSystem.messages.values)/4)
      if numPages<1 then numPages=1 end
    retVal.templateSmall={
      "                    "..pgNo.."/"..numPages.."  ",
      " MSG TITLE          STAT",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        "
      }
    line = 3
    startNo=table.getn(acarsSystem.messages.values)
    
    if pgNo>1 then startNo=table.getn(acarsSystem.messages.values)-((pgNo-1)*4) end
    endNo=startNo-3
    --print("startNo "..startNo.." endNo "..endNo)
    if endNo <1 then endNo=1 end
    for i = startNo,endNo , -1 do
      local ln="<"..acarsSystem.messages[i]["title"]
      local padding=21-string.len(ln)
      if padding<0 then padding=0 end
      if not acarsSystem.messages[i]["read"] then
	      retVal.template[line]=string.sub(ln,1,21) .. string.format("%"..padding.."s","").." NEW"
	--retVal.template[line]=string.sub(ln,1,21) .." NEW"
      else
	      retVal.template[line]=string.sub(ln,1,21) .. string.format("%"..padding.."s","").." OLD"
	--retVal.template[line]=string.sub(ln,1,21) .." OLD"
      end
      retVal.templateSmall[line+1]="            "..acarsSystem.messages[i]["time"]
      fmsFunctionsDefs["VIEWUPACARS"]["L"..(startNo-i+1)]={"showmessage",i}
      line = line+2
      
    end  
    return retVal
end

fmsPages["VIEWACARSLOG"]=createPage("VIEWACARSLOG")
acarsSystem.getLogMessages=function(pgNo)
  local onRecieved=table.getn(acarsSystem.messages.values)
  local onSent=table.getn(acarsSystem.messageSendQueue.values)
  local rmID=1
  local retVal={}
  local sMessage={}
  print("getLogMessages")
  while (onRecieved>0 or onSent>0) and rmID<6 do
    local rID=0
    local sID=0
    print("onRecieved "..onRecieved.." onSent "..onSent)
    if onRecieved>0 then
      rID=acarsSystem.messages[onRecieved]["messageID"]
    end
    if onSent>0 then
      sMessage=json.decode(acarsSystem.messageSendQueue[onSent])
      sID=sMessage["messageID"]
    end
    print("rID "..rID.." sID "..sID)
    if rID>sID then
      retVal[rmID]=acarsSystem.messages[onRecieved]
      retVal[rmID]["ud"]="U"
      rmID=rmID+1
      onRecieved=onRecieved-1
      print("use received message")
    else
      if sMessage["msg"]~=nil then
        retVal[rmID]=sMessage
        retVal[rmID]["ud"]="D"
        rmID=rmID+1
        onSent=onSent-1
        print("use sent message")
      else
        onSent=onSent-1
        print("skip sent message")
      end
    end
  end
  return retVal
end

acarsSystem.getMessageLog=function(pgNo)
  
  retVal={}
  retVal.template={
    "        ATC LOG         ",
    "                        ",
    "                        ", -- --"<Test Message           ",
    "                        ",
    "                        ", -- --"<2nd Test Message       ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "------------------------",
    "<INDEX        ERASE LOG>"
    
    } 
    numPages=math.ceil(table.getn(acarsSystem.messages.values)/5)+math.ceil(table.getn(acarsSystem.messageSendQueue.values)/5)
    if numPages<1 then numPages=1 end
  retVal.templateSmall={
    "                    "..pgNo.."/"..numPages.."  ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        "
    }

    local messageLog=acarsSystem.getLogMessages(pgNo)
    line = 2
    for i=1,table.getn(messageLog) do
      print("M "..i.." "..messageLog[i]["ud"])
      local ln=""
      if messageLog[i]["ud"]=="U" then
        if not messageLog[i]["read"] then
          retVal.templateSmall[line]=" "..messageLog[i]["time"].."z               NEW"
        else
          retVal.templateSmall[line]=" "..messageLog[i]["time"].."z               OLD"
        end
        ln="  "..messageLog[i]["title"]
        
      else
        retVal.templateSmall[line]=" "..messageLog[i]["time"].."z     RESPONSE RCVD"
        print("T "..messageLog[i]["msg"])
        ln="  "..messageLog[i]["msg"]
      end
      retVal.templateSmall[line+1]=messageLog[i]["ud"].."                       "
      ln=string.sub(ln,1,21)
      local padding=21-string.len(ln)
      if padding<=0 then 
        padding=0 
        ln=ln..".."
      else
        ln=ln.."  "
      end
      retVal.template[line+1]=ln .. string.format("%"..padding.."s","").." >"
      line = line+2
    end
    return retVal
end

dofile("acars/acars.pages.lua")
----

