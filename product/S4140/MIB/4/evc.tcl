#!/bin/tcl
#Author:andym
#Date: 2013-10-29

namespace eval evcoid {
	set tnEvcPortDEIMode(oid) 1.3.6.1.4.1.868.2.5.106.1.1.1.1.1
	set tnEvcPortDEIMode(type) INTEGER 
	set tnEvcPortDEIMode(access) read-write
	set tnEvcPortTagMode(oid) 1.3.6.1.4.1.868.2.5.106.1.1.1.1.2
	set tnEvcPortTagMode(type) INTEGER 
	set tnEvcPortTagMode(access) read-write
	set tnEvcPortAddressMode(oid) 1.3.6.1.4.1.868.2.5.106.1.1.1.1.3
	set tnEvcPortAddressMode(type) INTEGER 
	set tnEvcPortAddressMode(access) read-write
	set tnEvcNNIPortlist(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.2
	set tnEvcNNIPortlist(type) PortList 
	set tnEvcNNIPortlist(access) read-create
	set tnEvcVid(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.3
	set tnEvcVid(type) VlanIdOrAny 
	set tnEvcVid(access) read-create
	set tnEvcIVid(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.4
	set tnEvcIVid(type) VlanIdOrAny 
	set tnEvcIVid(access) read-create
	set tnEvcLearning(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.5
	set tnEvcLearning(type) INTEGER 
	set tnEvcLearning(access) read-create
	set tnEvcInnerTagType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.6
	set tnEvcInnerTagType(type) INTEGER 
	set tnEvcInnerTagType(access) read-create
	set tnEvcInnerVidMode(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.7
	set tnEvcInnerVidMode(type) INTEGER 
	set tnEvcInnerVidMode(access) read-create
	set tnEvcInnerVid(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.8
	set tnEvcInnerVid(type) VlanIdOrAnyOrNone 
	set tnEvcInnerVid(access) read-create
	set tnEvcInnerPCPDEIPreservation(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.9
	set tnEvcInnerPCPDEIPreservation(type) INTEGER 
	set tnEvcInnerPCPDEIPreservation(access) read-create
	set tnEvcInnerPCP(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.10
	set tnEvcInnerPCP(type) INTEGER 
	set tnEvcInnerPCP(access) read-create
	set tnEvcInnerDEI(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.11
	set tnEvcInnerDEI(type) INTEGER 
	set tnEvcInnerDEI(access) read-create
	set tnEvcOuterVid(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.12
	set tnEvcOuterVid(type) VlanIdOrAnyOrNone 
	set tnEvcOuterVid(access) read-create
	set tnEvcStatus(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.13
	set tnEvcStatus(type) RowStatus 
	set tnEvcStatus(access) read-create
	set tnEvcPolicerID(oid) 1.3.6.1.4.1.868.2.5.106.1.1.2.1.14
	set tnEvcPolicerID(type) INTEGER 
	set tnEvcPolicerID(access) read-create
	set tnEvcEceNextEceId(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.2
	set tnEvcEceNextEceId(type) INTEGER 
	set tnEvcEceNextEceId(access) read-create
	set tnEvcEceUNIPortlist(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.3
	set tnEvcEceUNIPortlist(type) PortList 
	set tnEvcEceUNIPortlist(access) read-create
	set tnEvcEceTagType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.4
	set tnEvcEceTagType(type) INTEGER 
	set tnEvcEceTagType(access) read-create
	set tnEvcEceTagVIDFilterType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.5
	set tnEvcEceTagVIDFilterType(type) INTEGER 
	set tnEvcEceTagVIDFilterType(access) read-create
	set tnEvcEceTagVIDFilterVal(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.6
	set tnEvcEceTagVIDFilterVal(type) VlanIdOrAnyOrNone 
	set tnEvcEceTagVIDFilterVal(access) read-create
	set tnEvcEceTagVIDFilterStart(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.7
	set tnEvcEceTagVIDFilterStart(type) VlanIdOrAnyOrNone 
	set tnEvcEceTagVIDFilterStart(access) read-create
	set tnEvcEceTagVIDFilterEnd(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.8
	set tnEvcEceTagVIDFilterEnd(type) VlanIdOrAnyOrNone 
	set tnEvcEceTagVIDFilterEnd(access) read-create
	set tnEvcEceTagPCP(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.9
	set tnEvcEceTagPCP(type) Bits 
	set tnEvcEceTagPCP(access) read-create
	set tnEvcEceTagDEI(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.10
	set tnEvcEceTagDEI(type) INTEGER 
	set tnEvcEceTagDEI(access) read-create
	set tnEvcEceTagFrameType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.11
	set tnEvcEceTagFrameType(type) INTEGER 
	set tnEvcEceTagFrameType(access) read-create
	set tnEvcEceProtoType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.12
	set tnEvcEceProtoType(type) INTEGER 
	set tnEvcEceProtoType(access) read-create
	set tnEvcEceProtoVal(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.13
	set tnEvcEceProtoVal(type) INTEGER 
	set tnEvcEceProtoVal(access) read-create
	set tnEvcEceDscpFilterType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.14
	set tnEvcEceDscpFilterType(type) INTEGER 
	set tnEvcEceDscpFilterType(access) read-create
	set tnEvcEceDscpFilterVal(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.15
	set tnEvcEceDscpFilterVal(type) INTEGER 
	set tnEvcEceDscpFilterVal(access) read-create
	set tnEvcEceDscpRangeStart(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.16
	set tnEvcEceDscpRangeStart(type) INTEGER 
	set tnEvcEceDscpRangeStart(access) read-create
	set tnEvcEceDscpRangeEnd(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.17
	set tnEvcEceDscpRangeEnd(type) INTEGER 
	set tnEvcEceDscpRangeEnd(access) read-create
	set tnEvcEceSrcPortFilterType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.18
	set tnEvcEceSrcPortFilterType(type) INTEGER 
	set tnEvcEceSrcPortFilterType(access) read-create
	set tnEvcEceSrcPortFilterNo(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.19
	set tnEvcEceSrcPortFilterNo(type) INTEGER 
	set tnEvcEceSrcPortFilterNo(access) read-create
	set tnEvcEceSrcPortRangeStart(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.20
	set tnEvcEceSrcPortRangeStart(type) INTEGER 
	set tnEvcEceSrcPortRangeStart(access) read-create
	set tnEvcEceSrcPortRangeEnd(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.21
	set tnEvcEceSrcPortRangeEnd(type) INTEGER 
	set tnEvcEceSrcPortRangeEnd(access) read-create
	set tnEvcEceDstPortFilterType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.22
	set tnEvcEceDstPortFilterType(type) INTEGER 
	set tnEvcEceDstPortFilterType(access) read-create
	set tnEvcEceDstPortFilterNo(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.23
	set tnEvcEceDstPortFilterNo(type) INTEGER 
	set tnEvcEceDstPortFilterNo(access) read-create
	set tnEvcEceDstPortRangeStart(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.24
	set tnEvcEceDstPortRangeStart(type) INTEGER 
	set tnEvcEceDstPortRangeStart(access) read-create
	set tnEvcEceDstPortRangeEnd(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.25
	set tnEvcEceDstPortRangeEnd(type) INTEGER 
	set tnEvcEceDstPortRangeEnd(access) read-create
	set tnEvcEceIpv4DipSipFilter(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.26
	set tnEvcEceIpv4DipSipFilter(type) INTEGER 
	set tnEvcEceIpv4DipSipFilter(access) read-create
	set tnEvcEceIpv4DipSipAddr(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.27
	set tnEvcEceIpv4DipSipAddr(type) InetAddress 
	set tnEvcEceIpv4DipSipAddr(access) read-create
	set tnEvcEceIpv4DipSipMask(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.28
	set tnEvcEceIpv4DipSipMask(type) InetAddress 
	set tnEvcEceIpv4DipSipMask(access) read-create
	set tnEvcEceIpv4Fragment(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.29
	set tnEvcEceIpv4Fragment(type) INTEGER 
	set tnEvcEceIpv4Fragment(access) read-create
	set tnEvcEceIpv6DipSipFilter(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.30
	set tnEvcEceIpv6DipSipFilter(type) INTEGER 
	set tnEvcEceIpv6DipSipFilter(access) read-create
	set tnEvcEceIpv6DipSipAddr(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.31
	set tnEvcEceIpv6DipSipAddr(type) Integer32 
	set tnEvcEceIpv6DipSipAddr(access) read-create
	set tnEvcEceIpv6DipSipMask(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.32
	set tnEvcEceIpv6DipSipMask(type) Integer32 
	set tnEvcEceIpv6DipSipMask(access) read-create
	set tnEvcEceOuterMode(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.33
	set tnEvcEceOuterMode(type) INTEGER 
	set tnEvcEceOuterMode(access) read-create
	set tnEvcEceOuterPCPDEIPreserve(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.34
	set tnEvcEceOuterPCPDEIPreserve(type) INTEGER 
	set tnEvcEceOuterPCPDEIPreserve(access) read-create
	set tnEvcEceOuterPCP(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.35
	set tnEvcEceOuterPCP(type) INTEGER 
	set tnEvcEceOuterPCP(access) read-create
	set tnEvcEceOuterDEI(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.36
	set tnEvcEceOuterDEI(type) INTEGER 
	set tnEvcEceOuterDEI(access) read-create
	set tnEvcEceActDirection(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.37
	set tnEvcEceActDirection(type) INTEGER 
	set tnEvcEceActDirection(access) read-create
	set tnEvcEceActEvcidFilterType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.38
	set tnEvcEceActEvcidFilterType(type) INTEGER 
	set tnEvcEceActEvcidFilterType(access) read-create
	set tnEvcEceActEvcidVal(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.39
	set tnEvcEceActEvcidVal(type) INTEGER 
	set tnEvcEceActEvcidVal(access) read-create
	set tnEvcEceActTagPopCount(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.40
	set tnEvcEceActTagPopCount(type) INTEGER 
	set tnEvcEceActTagPopCount(access) read-create
	set tnEvcEceActPolicyId(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.41
	set tnEvcEceActPolicyId(type) INTEGER 
	set tnEvcEceActPolicyId(access) read-create
	set tnEvcEceActClass(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.42
	set tnEvcEceActClass(type) INTEGER 
	set tnEvcEceActClass(access) read-create
	set tnEvcEceDMacSMacFilterType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.43
	set tnEvcEceDMacSMacFilterType(type) INTEGER 
	set tnEvcEceDMacSMacFilterType(access) read-create
	set tnEvcEceDMacSMacVal(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.44
	set tnEvcEceDMacSMacVal(type) MacAddress 
	set tnEvcEceDMacSMacVal(access) read-create
	set tnEvcEceDMacType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.45
	set tnEvcEceDMacType(type) INTEGER 
	set tnEvcEceDMacType(access) read-create
	set tnEvcEceStatus(oid) 1.3.6.1.4.1.868.2.5.106.1.1.3.1.46
	set tnEvcEceStatus(type) RowStatus 
	set tnEvcEceStatus(access) read-create
	set tnEvcBandwidthProfilesPolicerMode(oid) 1.3.6.1.4.1.868.2.5.106.1.1.4.1.2
	set tnEvcBandwidthProfilesPolicerMode(type) INTEGER 
	set tnEvcBandwidthProfilesPolicerMode(access) read-create
	set tnEvcBandwidthProfilesCIR(oid) 1.3.6.1.4.1.868.2.5.106.1.1.4.1.3
	set tnEvcBandwidthProfilesCIR(type) INTEGER 
	set tnEvcBandwidthProfilesCIR(access) read-create
	set tnEvcBandwidthProfilesCBS(oid) 1.3.6.1.4.1.868.2.5.106.1.1.4.1.4
	set tnEvcBandwidthProfilesCBS(type) INTEGER 
	set tnEvcBandwidthProfilesCBS(access) read-create
	set tnEvcBandwidthProfilesEIR(oid) 1.3.6.1.4.1.868.2.5.106.1.1.4.1.5
	set tnEvcBandwidthProfilesEIR(type) INTEGER 
	set tnEvcBandwidthProfilesEIR(access) read-create
	set tnEvcBandwidthProfilesEBS(oid) 1.3.6.1.4.1.868.2.5.106.1.1.4.1.6
	set tnEvcBandwidthProfilesEBS(type) INTEGER 
	set tnEvcBandwidthProfilesEBS(access) read-create
	set tnEvcBandwidthProfilesState(oid) 1.3.6.1.4.1.868.2.5.106.1.1.4.1.7
	set tnEvcBandwidthProfilesState(type) INTEGER 
	set tnEvcBandwidthProfilesState(access) read-create
	set tnEvcL2cpCfgType(oid) 1.3.6.1.4.1.868.2.5.106.1.3.3.1.3
	set tnEvcL2cpCfgType(type) INTEGER 
	set tnEvcL2cpCfgType(access) read-create
	set tnEvcL2cpCfgMatchScope(oid) 1.3.6.1.4.1.868.2.5.106.1.3.3.1.4
	set tnEvcL2cpCfgMatchScope(type) INTEGER 
	set tnEvcL2cpCfgMatchScope(access) read-create
	set tnEvcL2cpCfgMacAddress(oid) 1.3.6.1.4.1.868.2.5.106.1.3.3.1.5
	set tnEvcL2cpCfgMacAddress(type) MacAddress 
	set tnEvcL2cpCfgMacAddress(access) read-create
	set tnEvcL2cpCfgProtocol(oid) 1.3.6.1.4.1.868.2.5.106.1.3.3.1.6
	set tnEvcL2cpCfgProtocol(type) Unsigned32 
	set tnEvcL2cpCfgProtocol(access) read-create
	set tnEvcL2cpCfgSubType(oid) 1.3.6.1.4.1.868.2.5.106.1.3.3.1.7
	set tnEvcL2cpCfgSubType(type) Unsigned32 
	set tnEvcL2cpCfgSubType(access) read-create
	set tnEvcL2cpCfgEvcName(oid) 1.3.6.1.4.1.868.2.5.106.1.3.3.1.8
	set tnEvcL2cpCfgEvcName(type) OctetString 
	set tnEvcL2cpCfgEvcName(access) read-create
	set tnEvcL2cpCfgValid(oid) 1.3.6.1.4.1.868.2.5.106.1.3.3.1.9
	set tnEvcL2cpCfgValid(type) INTEGER 
	set tnEvcL2cpCfgValid(access) read-create
	set tnEvcEceInnerTagType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.1
	set tnEvcEceInnerTagType(type) INTEGER 
	set tnEvcEceInnerTagType(access) read-create
	set tnEvcEceInnerTagVIDFilterType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.2
	set tnEvcEceInnerTagVIDFilterType(type) INTEGER 
	set tnEvcEceInnerTagVIDFilterType(access) read-create
	set tnEvcEceInnerTagVIDFilterVal(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.3
	set tnEvcEceInnerTagVIDFilterVal(type) VlanIdOrNone 
	set tnEvcEceInnerTagVIDFilterVal(access) read-create
	set tnEvcEceInnerTagVIDFilterStart(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.4
	set tnEvcEceInnerTagVIDFilterStart(type) VlanIdOrNone 
	set tnEvcEceInnerTagVIDFilterStart(access) read-create
	set tnEvcEceInnerTagVIDFilterEnd(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.5
	set tnEvcEceInnerTagVIDFilterEnd(type) VlanIdOrNone 
	set tnEvcEceInnerTagVIDFilterEnd(access) read-create
	set tnEvcEceInnerTagPCP(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.6
	set tnEvcEceInnerTagPCP(type) Bits 
	set tnEvcEceInnerTagPCP(access) read-create
	set tnEvcEceInnerTagDEI(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.7
	set tnEvcEceInnerTagDEI(type) INTEGER 
	set tnEvcEceInnerTagDEI(access) read-create
	set tnEvcEcePolicer(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.8
	set tnEvcEcePolicer(type) INTEGER 
	set tnEvcEcePolicer(access) read-create
	set tnEvcEceOuterVid(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.9
	set tnEvcEceOuterVid(type) VlanIdOrNone 
	set tnEvcEceOuterVid(access) read-create
	set tnEvcEceNNIInnerTagType(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.10
	set tnEvcEceNNIInnerTagType(type) INTEGER 
	set tnEvcEceNNIInnerTagType(access) read-create
	set tnEvcEceInnerVid(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.11
	set tnEvcEceInnerVid(type) VlanIdOrNone 
	set tnEvcEceInnerVid(access) read-create
	set tnEvcEceInnerPCPDEIPreserve(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.12
	set tnEvcEceInnerPCPDEIPreserve(type) INTEGER 
	set tnEvcEceInnerPCPDEIPreserve(access) read-create
	set tnEvcEceInnerPCP(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.13
	set tnEvcEceInnerPCP(type) INTEGER 
	set tnEvcEceInnerPCP(access) read-create
	set tnEvcEceInnerDEI(oid) 1.3.6.1.4.1.868.2.5.106.1.1.5.1.14
	set tnEvcEceInnerDEI(type) INTEGER 
	set tnEvcEceInnerDEI(access) read-create
	set tnEvcStatGreenFrameRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.1.1.2
	set tnEvcStatGreenFrameRx(type) Counter64 
	set tnEvcStatGreenFrameRx(access) read-only
	set tnEvcStatGreenFrameTx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.1.1.3
	set tnEvcStatGreenFrameTx(type) Counter64 
	set tnEvcStatGreenFrameTx(access) read-only
	set tnEvcStatYellowFrameRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.1.1.4
	set tnEvcStatYellowFrameRx(type) Counter64 
	set tnEvcStatYellowFrameRx(access) read-only
	set tnEvcStatYellowFrameTx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.1.1.5
	set tnEvcStatYellowFrameTx(type) Counter64 
	set tnEvcStatYellowFrameTx(access) read-only
	set tnEvcStatRedFrameRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.1.1.6
	set tnEvcStatRedFrameRx(type) Counter64 
	set tnEvcStatRedFrameRx(access) read-only
	set tnEvcStatDiscardGreenFrame(oid) 1.3.6.1.4.1.868.2.5.106.1.2.1.1.7
	set tnEvcStatDiscardGreenFrame(type) Counter64 
	set tnEvcStatDiscardGreenFrame(access) read-only
	set tnEvcStatDiscardYellowFrame(oid) 1.3.6.1.4.1.868.2.5.106.1.2.1.1.8
	set tnEvcStatDiscardYellowFrame(type) Counter64 
	set tnEvcStatDiscardYellowFrame(access) read-only
	set tnEvcStatClear(oid) 1.3.6.1.4.1.868.2.5.106.1.2.1.1.9
	set tnEvcStatClear(type) TruthValue 
	set tnEvcStatClear(access) read-write
	set tnEvcExtStatGreenFrameRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.4
	set tnEvcExtStatGreenFrameRx(type) Counter64 
	set tnEvcExtStatGreenFrameRx(access) read-only
	set tnEvcExtStatGreenFrameTx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.5
	set tnEvcExtStatGreenFrameTx(type) Counter64 
	set tnEvcExtStatGreenFrameTx(access) read-only
	set tnEvcExtStatGreenBytesRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.6
	set tnEvcExtStatGreenBytesRx(type) Counter64 
	set tnEvcExtStatGreenBytesRx(access) read-only
	set tnEvcExtStatGreenBytesTx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.7
	set tnEvcExtStatGreenBytesTx(type) Counter64 
	set tnEvcExtStatGreenBytesTx(access) read-only
	set tnEvcExtStatYellowFrameRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.8
	set tnEvcExtStatYellowFrameRx(type) Counter64 
	set tnEvcExtStatYellowFrameRx(access) read-only
	set tnEvcExtStatYellowFrameTx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.9
	set tnEvcExtStatYellowFrameTx(type) Counter64 
	set tnEvcExtStatYellowFrameTx(access) read-only
	set tnEvcExtStatYellowBytesRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.10
	set tnEvcExtStatYellowBytesRx(type) Counter64 
	set tnEvcExtStatYellowBytesRx(access) read-only
	set tnEvcExtStatYellowBytesTx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.11
	set tnEvcExtStatYellowBytesTx(type) Counter64 
	set tnEvcExtStatYellowBytesTx(access) read-only
	set tnEvcExtStatRedFrameRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.12
	set tnEvcExtStatRedFrameRx(type) Counter64 
	set tnEvcExtStatRedFrameRx(access) read-only
	set tnEvcExtStatRedBytesRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.13
	set tnEvcExtStatRedBytesRx(type) Counter64 
	set tnEvcExtStatRedBytesRx(access) read-only
	set tnEvcExtStatDiscardFrameRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.14
	set tnEvcExtStatDiscardFrameRx(type) Counter64 
	set tnEvcExtStatDiscardFrameRx(access) read-only
	set tnEvcExtStatDiscardFrameTx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.15
	set tnEvcExtStatDiscardFrameTx(type) Counter64 
	set tnEvcExtStatDiscardFrameTx(access) read-only
	set tnEvcExtStatDiscardBytesRx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.16
	set tnEvcExtStatDiscardBytesRx(type) Counter64 
	set tnEvcExtStatDiscardBytesRx(access) read-only
	set tnEvcExtStatDiscardBytesTx(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.17
	set tnEvcExtStatDiscardBytesTx(type) Counter64 
	set tnEvcExtStatDiscardBytesTx(access) read-only
	set tnEvcExtStatclear(oid) 1.3.6.1.4.1.868.2.5.106.1.2.2.1.18
	set tnEvcExtStatclear(type) TruthValue 
	set tnEvcExtStatclear(access) read-write
}
namespace import util::*
namespace eval evc {
    namespace export *
}
proc evc::test {evcid PortList} {
	set index $evcid
	set cmd "exec snmpset $::session"

	set str [setOid $evcid::tnEvcNNIPortlist $evcid 0xd0]
	puts "str is $str"
}

proc evc::evcAdd {evcid portlist} {
	set index $evcid
	set cmd "exec snmpset $::session"
	puts "adding new evc $evcid in $portlist"

	set setPortlist "$evcid::tnEvcNNIPortlist(oid).$index [getType $evcid::tnEvcNNIPortlist(type) $portlist]"
	set rSt "$evcid::tnEvcStatus(oid).$index [getType $evcid::tnEvcStatus(type)] 4"
	append cmd " $setPortlist $rSt"
	set ret [catch {eval $cmd} error]
    if { $ret } { puts $error ;puts "evc::evcadd commit $evcid $portlist Failed";return 0}
	puts "evc::evcadd commit $evcid $portlist success"
}

proc evc::evcIvidSet {evcid vid ivid } {
	set index $evcid
	set cmd "exec snmpset $::session"

	set setVid "$evcoid::tnEvcVid(oid).$index [getType $evcoid::tnEvcVid(type)] $vid"
	set setIvid "$evcoid::tnEvcIVid(oid).$index [getType $evcoid]"
}
