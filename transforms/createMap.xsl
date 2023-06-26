<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xpf="http://www.w3.org/2005/xpath-functions"
  version="3.0">
  
  <xsl:output indent="yes"/>
  <xsl:param name="jsonFile"/>
  <!--<xsl:variable name="jsonOut" as="document-node()" select="json-to-xml(unparsed-text($jsonFile))"/>-->

  <xsl:template name="init">
    <all>
    <xsl:sequence select="json-to-xml(unparsed-text($jsonFile))"/>
    <!--<strings>
     <publicComment>
       <xsl:sequence select="$jsonOut//xpf:map[xpf:string[@key='publicComment']]/xpf:string[@key='id']"></xsl:sequence>
     </publicComment>
      <targetFootnote>
        <xsl:sequence select="$jsonOut//xpf:map[xpf:boolean[@key='showTargetInFootnote' and . = true()]]"></xsl:sequence>
      </targetFootnote>
      
    </strings>-->
    </all>
  </xsl:template>

</xsl:stylesheet>