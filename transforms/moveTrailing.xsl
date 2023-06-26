<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.gpo.gov/xml/uslm"
  xmlns:uslm="http://schemas.gpo.gov/xml/uslm" xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:functx="http://www.functx.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:xpf="http://www.w3.org/2005/xpath-functions" xmlns:err="http://www.w3.org/2005/xqt-errors"
  xmlns:olrc="http://uscode.house.gov"
  exclude-result-prefixes="#default xs xsi dc uslm xhtml functx map xpf err olrc functx"
  version="3.0">
  
  <!-- This module moves the trailing punctuation to within the quotedContent block for styling 
  (not semantic) reasons. -->
  
  <!--<xsl:template match="uslm:quotedContent[not(child::uslm:b|child::uslm:i|child::uslm:shortTitle)]
    [child::uslm:*]
    [following::text()[1][matches(.,'^;$') or matches(.,'^; and$') or matches(.,'^\.$')]]">
    
    <!-\- could do analyze-string on the closing quote character to add the trailing punctuation?
    or look for the quotedContent child character and add, since the " is on a child/descendant? -\->
    <!-\- if looking for the closing quote, could look for immediately following text sibling that 
    matches the correct regex-\->
  </xsl:template>-->
  
  <xsl:template match="text()[matches(.,'”$')][ancestor::uslm:quotedContent[not(child::uslm:b|child::uslm:i|child::uslm:shortTitle)]
    [child::uslm:*]
    [following::text()[1][matches(.,'^;(\s)*$') or matches(.,'^; and(\s)*$') or matches(.,'^\.(\s)*$')]]]">
    <xsl:variable name="current" select="."/>
    <xsl:analyze-string select="." regex="(”)$">
      <xsl:matching-substring><xsl:value-of select="regex-group(1)"/><inline 
        class="inline afterQuotedContent"><xsl:value-of 
          select="$current/following::text()[1][matches(.,'^;(\s)*$') or matches(.,'^; and(\s)*$') or matches(.,'^\.(\s)*$')]"/></inline></xsl:matching-substring>
      <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>
  
  <xsl:template match="text()[matches(.,'^;(\s)*$') or matches(.,'^; and(\s)*$') or matches(.,'^\.(\s)*$')]
    [preceding::text()[1][matches(.,'”$')][ancestor::uslm:quotedContent[not(child::uslm:b|child::uslm:i|child::uslm:shortTitle)]
    [child::uslm:*]]]"/>
</xsl:stylesheet>