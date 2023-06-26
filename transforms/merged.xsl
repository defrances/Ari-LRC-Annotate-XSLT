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
      <xd:p>Return the sidenote(s) for the merged provisions. </xd:p>
    </xd:desc>
    <xd:param name="id-merged">The id-merged map with the information about the ids of the merged granules,
    the classification, the public comments, and the stamps (if any)</xd:param>
    <xd:param name="mergeId">The first provision's id attribute value.</xd:param>
  </xd:doc>
  <xsl:template name="mergedProvisions">
    <xsl:param name="id-merged" as="map(xs:string, xs:string*)" required="yes"/>
    <xsl:param name="mergeId" as="xs:string"/>
    <xsl:variable name="content" select="map:get($id-merged, $mergeId)"/>
    <xsl:variable name="after" select="$content[1]"/>
    <xsl:variable name="classification" select="$content[2]"/>
    <xsl:variable name="comment" select="$content[3]"/>
    <xsl:variable name="stamp" select="$content[4]"/>
    <sidenote topic="olrcClassification">
      <xsl:choose>
        <xsl:when test="string-length($classification) > 30">
          <xsl:attribute name="role">merged, longTarget</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="role">merged, target</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:attribute name="misc">
        <xsl:sequence select="concat($mergeId, ',', $after)"/>
      </xsl:attribute>
      <xsl:if test="$content[4]">
        <xsl:attribute name="note" select="$content[4]"/>
      </xsl:if>
      <xsl:analyze-string select="$classification" regex="t(\d+)/s(\d+)">
        <xsl:matching-substring><xsl:value-of select="concat(regex-group(1),'/',regex-group(2))"/></xsl:matching-substring>
        <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
      </xsl:analyze-string>
    </sidenote>
    <xsl:if test="$content[3]">
      <sidenote topic="olrcClassification" role="merged, publicComment">
        <xsl:analyze-string select="$content[3]" regex="\\n">
          <xsl:matching-substring>
            <br/>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:sequence select="."/>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </sidenote>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>