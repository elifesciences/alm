<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:rss="http://purl.org/rss/2.0/"
                xmlns:atom="http://www.w3.org/2005/Atom"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dc="http://purl.org/dc/elements/1.1/">

  <xsl:output method="text" indent="yes"/>

  <xsl:template match="/rss/channel">
    <xsl:for-each select="item">
      <xsl:apply-templates select="guid"/>
      <xsl:text>&#x20;</xsl:text>
      <xsl:apply-templates select="dc:date"/>
      <xsl:text>&#x20;</xsl:text>
      <xsl:value-of select="title"/>
      <xsl:text>&#x0A;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- print nothing that's not explicitly output -->
  <xsl:template match="text()"/>

  <!-- strip the time and timezone component from date -->
  <xsl:template match="dc:date">
    <xsl:value-of select="substring(.,0,11)"/>
  </xsl:template>

  <xsl:template match="guid[1]">
    <xsl:value-of select="substring(.,19)"/>
  </xsl:template>


</xsl:stylesheet>
 
