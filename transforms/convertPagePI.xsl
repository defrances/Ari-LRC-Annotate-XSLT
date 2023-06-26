<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://schemas.gpo.gov/xml/uslm"
  exclude-result-prefixes="xs"
  version="1.0">
  
  <xsl:template match="/|@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="processing-instruction('page')">
    <page>
      <xsl:attribute name="id"><xsl:value-of select="concat('page',.)"/></xsl:attribute>
      <xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
    </page>
    <xsl:processing-instruction name="page"><xsl:value-of select="."/></xsl:processing-instruction>
  </xsl:template>
</xsl:stylesheet>