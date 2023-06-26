<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.gpo.gov/xml/uslm"
  xmlns:uslm="http://schemas.gpo.gov/xml/uslm" xmlns:olrc="http://uscode.house.gov"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"  xmlns:functx="http://www.functx.com" 
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:xpf="http://www.w3.org/2005/xpath-functions"
  exclude-result-prefixes="#default xs uslm xhtml map xpf olrc functx" version="3.0">
  
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Create the sidenote with the target information. The length of string (30)
      is chosen as a reasonable length given the current formatting. </xd:p>
    </xd:desc>
    <xd:param name="targetMap"></xd:param>
    <xd:param name="locationId"></xd:param>
    <xd:param name="targetInFootnoteMap"></xd:param>
    <xd:param name="docMetaMap"></xd:param>
  </xd:doc>
  <xsl:template name="createTargetSidenote">
    <xsl:param name="targetMap" as="map(*)"/>
    <xsl:param name="locationId" as="xs:string"/>
    <xsl:param name="targetInFootnoteMap" as="map(*)?"/>
    <xsl:param name="docMetaMap" as="map(*)?"/>
    <sidenote topic="olrcClassification">
      <xsl:variable name="tempTarget" select="map:get($targetMap,$locationId)"/>
      <xsl:variable name="targetFootnote" select="map:get($targetInFootnoteMap,$locationId)"/>
      <xsl:variable name="metaStamp" select="map:get($docMetaMap,$locationId)"/>
      <xsl:choose>
        <xsl:when test="matches($tempTarget,'^out$','i')">
          <xsl:attribute name="class">out</xsl:attribute>
          <xsl:if test="$metaStamp">
            <xsl:attribute name="note" select="$metaStamp"/>
          </xsl:if>
          <xsl:text>✓</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <!--  or $targetFootnote -->
          <xsl:choose>
            <xsl:when test="string-length($tempTarget)>30 or $targetFootnote">
              <xsl:attribute name="role">longTarget</xsl:attribute>
            </xsl:when>
            <xsl:otherwise><xsl:attribute name="role">target</xsl:attribute></xsl:otherwise>
          </xsl:choose>
          <xsl:if test="$metaStamp">
            <xsl:attribute name="note" select="$metaStamp"/>
          </xsl:if>
          <xsl:analyze-string select="$tempTarget" regex="t(\d+A?)/s(\d+)">
            <xsl:matching-substring><xsl:value-of select="concat(regex-group(1),'/',regex-group(2))"/></xsl:matching-substring>
            <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
          </xsl:analyze-string>
        </xsl:otherwise>
      </xsl:choose>
    </sidenote>
  </xsl:template>
  
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>Add the page information to the top of each page.</xd:p>
    </xd:desc>
    <xd:param name="pageInfo"></xd:param>
    <xd:param name="pageNumber"></xd:param>
  </xd:doc>
  <xsl:template name="createPageInfo">
    <xsl:param name="pageInfo" as="element()*"/>
    <xsl:param name="pageNumber" as="xs:double"/>
    <notes topic="olrcClassification">
      <xsl:if test="$pageInfo/xpf:string[@key='publaw']">
        <xsl:text>&#xa;</xsl:text>
        <note role="pLaw">
          <xsl:text>Pub. L. </xsl:text><xsl:value-of select="$pageInfo/xpf:string[@key='publaw']"/>
        </note>
      </xsl:if>
      <xsl:if test="$pageInfo/xpf:string[@key='enacted_date'] and string-length($pageInfo/xpf:string[@key='enacted_date']) > 5">
        <xsl:text>&#xa;</xsl:text>
        <note role="enactDate">
          <xsl:variable name="stage1" select="format-date(xs:date($pageInfo/xpf:string[@key='enacted_date']),'[MNn,*-3]. [D], [Y]')"/>
            <xsl:value-of select="functx:replace-multi($stage1,
              ('May.','Jun.','Jul.','Sep.'),
              ('May','June','July','Sept.'))"/>
        </note>
      </xsl:if>
      <xsl:if test="$pageInfo/xpf:number[@key='statpage']">
        <xsl:text>&#xa;</xsl:text>
        <note role="statute">
          <xsl:attribute name="id"><xsl:value-of select="concat('statpage',$pageInfo/xpf:number[@key='statpage']+$pageNumber)"/></xsl:attribute>
          <xsl:value-of select="$pageInfo/xpf:string[@key='statvolume']"/>
          <xsl:text> Stat. </xsl:text>
          <xsl:value-of select="$pageInfo/xpf:number[@key='statpage']+$pageNumber"/>
        </note>
      </xsl:if>
    </notes>
  </xsl:template>
</xsl:stylesheet>
