<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Nov 12, 2015</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> johannes</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="no"/>
    <xsl:param name="staff.id" as="xs:string"/>
    <xsl:param name="rdg.id" as="xs:string"/>
    <xsl:variable name="staff" select="id($staff.id)" as="node()"/>
    <xsl:variable name="rdg" select="id($rdg.id)" as="node()"/>
    <xsl:variable name="main.source" select="tokenize($rdg/replace(@source,'#',''),' ')[1]" as="xs:string"/>
    <xsl:variable name="controlEvents" select="$staff/parent::mei:measure//mei:*[@staff = $staff/@n and (not(ancestor::mei:rdg) or $main.source = tokenize(ancestor::mei:rdg/replace(@source,'#',''),' '))]" as="node()*"/>
    <xsl:template match="/">
        <mei xmlns="http://www.music-encoding.org/ns/mei">
            <music>
                <body>
                    <mdiv>
                        <score>
                            <scoreDef>
                                <xsl:variable name="meter" select="$staff/preceding::mei:scoreDef[@meter.unit and @meter.count][1]" as="node()"/>
                                <xsl:attribute name="meter.unit" select="$meter/@meter.unit"/>
                                <xsl:attribute name="meter.count" select="$meter/@meter.unit"/>
                                <staffGrp>
                                    <staffDef n="{$staff/@n}" lines="5">
                                        <xsl:variable name="clef" select="$staff/preceding::mei:*[(local-name() = 'staffDef' and @n = $staff/@n and @clef.shape) or (local-name() = 'clef' and ancestor::mei:staff[@n = $staff/@n])][1]" as="node()"/>
                                        <xsl:variable name="key" select="$staff/preceding::mei:*[@key.sig and (local-name() = 'scoreDef' or (local-name() = 'staffDef' and @n = $staff/@n))][1]" as="node()"/>
                                        <xsl:attribute name="clef.shape" select="if(local-name($clef) = 'clef') then($clef/@shape) else($clef/@clef.shape)"/>
                                        <xsl:attribute name="clef.line" select="if(local-name($clef) = 'clef') then($clef/@line) else($clef/@clef.line)"/>
                                        <xsl:attribute name="key.sig" select="$key/@key.sig"/>
                                    </staffDef>
                                </staffGrp>
                            </scoreDef>
                            <section>
                                <measure>
                                    <xsl:apply-templates select="$staff"/>
                                    <xsl:apply-templates select="$controlEvents"/>
                                </measure>
                            </section>
                        </score>
                    </mdiv>
                </body>
            </music>
        </mei>
    </xsl:template>
    <xsl:template match="mei:meiHead"/>
    <xsl:template match="mei:app">
        <xsl:apply-templates select="mei:rdg[$main.source = tokenize(replace(@source,'#',''),' ')]/child::mei:*"/>
    </xsl:template>
    <xsl:template match="@artic">
        <xsl:attribute name="artic">
            <xsl:choose>
                <xsl:when test="string(.) = 'dot'">stacc</xsl:when>
                <xsl:when test="string(.) = 'stroke'">spicc</xsl:when>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>