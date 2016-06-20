<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei xhtml" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Oct 30, 2015</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> johannes</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xhtml" indent="no" exclude-result-prefixes="#all" omit-xml-declaration="yes"/>
    <xsl:function name="mei:resolveSources">
        <xsl:param name="sources" as="xs:string"/>
        <xsl:variable name="tokens" select="tokenize(replace($sources,'#',''),' ')" as="xs:string*"/>
        <xsl:for-each select="$tokens">
            <xsl:choose>
                <xsl:when test=". = 'A'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">A</span>
                </xsl:when>
                <xsl:when test=". = 'KA1'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">K<sup>A</sup>
                        <sub>1</sub>
                    </span>
                </xsl:when>
                <xsl:when test=". = 'KA2'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">K<sup>A</sup>
                        <sub>2</sub>
                    </span>
                </xsl:when>
                <xsl:when test=". = 'KA9'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">K<sup>A</sup>
                        <sub>9</sub>
                    </span>
                </xsl:when>
                <xsl:when test=". = 'K13'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">K<sub>13</sub>
                    </span>
                </xsl:when>
                <xsl:when test=". = 'K15'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">K<sub>15</sub>
                    </span>
                </xsl:when>
                <xsl:when test=". = 'KA19'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">K<sup>A</sup>
                        <sub>19</sub>
                    </span>
                </xsl:when>
                <xsl:when test=". = 'K20'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">K<sub>20</sub>
                    </span>
                </xsl:when>
                <xsl:when test=". = 'KA26'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">K<sup>A</sup>
                        <sub>26</sub>
                    </span>
                </xsl:when>
                <xsl:when test=". = 'D1849'">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="siglum">D<sub>1849</sub>
                    </span>
                </xsl:when>
                <xsl:otherwise>
                    <span xmlns="http://www.w3.org/1999/xhtml" class="unknown">
                        <xsl:value-of select="."/>
                    </span>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="position() lt (count($tokens) - 1)">
                <span xmlns="http://www.w3.org/1999/xhtml">, </span>
            </xsl:if>
            <xsl:if test="position() = (count($tokens) - 1)">
                <span xmlns="http://www.w3.org/1999/xhtml"> and </span>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>
    <xsl:function name="mei:getOrdinal">
        <xsl:param name="number"/>
        <xsl:value-of select="$number"/>
        
        <!-- a little parameter sanity check (integer > 0) -->
        <xsl:if test="             translate($number, '0123456789', '') = ''             and             $number &gt; 0             ">
            <xsl:variable name="mod100" select="$number mod 100"/>
            <xsl:variable name="mod10" select="$number mod 10"/>
            <xsl:choose>
                <xsl:when test="$mod100 = 11 or $mod100 = 12 or $mod100 = 13">
                    <xsl:text>th</xsl:text>
                </xsl:when>
                <xsl:when test="$mod10 = 1">
                    <xsl:text>st</xsl:text>
                </xsl:when>
                <xsl:when test="$mod10 = 2">
                    <xsl:text>nd</xsl:text>
                </xsl:when>
                <xsl:when test="$mod10 = 3">
                    <xsl:text>rd</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>th</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:function>
    <xsl:function name="mei:resolveTstamp2">
        <xsl:param name="tstamp2" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="not(contains($tstamp2,'m+'))">
                <xsl:value-of select="concat(' ending on timestamp ',$tstamp2)"/>
            </xsl:when>
            <xsl:when test="starts-with($tstamp2,'0m+')">
                <xsl:value-of select="concat(' ending on timestamp ',substring-after($tstamp2,'m+'))"/>
            </xsl:when>
            <xsl:when test="starts-with($tstamp2,'1m+')">
                <xsl:value-of select="concat(' ending on timestamp ',substring-after($tstamp2,'m+'),' of the following measure')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(' ending on timestamp ',substring-after($tstamp2,'m+'), ' of the ',mei:getOrdinal(substring-before($tstamp2,'m+')))"/>-next measure</xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="local-name(/mei:*) = 'annot'">
                <xsl:apply-templates select="//mei:p"/>
            </xsl:when>
            <xsl:when test="local-name(/mei:*) = 'app'">
                <xsl:variable name="app" select="/mei:app" as="node()"/>
                <xsl:variable name="decls" select="/mei:app/tokenize(replace(@decls,'#ediromAnnotCategory_',''),' ')" as="xs:string*"/>
                <xsl:variable name="tstamp.min" select="string(min(//number(@tstamp)))" as="xs:string"/>
                <xsl:variable name="tstamp.max" select="string(max(//number(@tstamp)))" as="xs:string"/>
                <xsl:if test="'articulation' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">
                        Differing articulation: Source<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[1]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[1]//@artic"> read<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then(' ')else('s ')"/>
                                <em>
                                    <xsl:value-of select="string-join($app/mei:rdg[1]//@artic,', ')"/>
                                </em>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve')else('s')"/> no @artic</xsl:otherwise>
                        </xsl:choose>, while source<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[2]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[2]//@artic"> read<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then(' ')else('s ')"/>
                                <em>
                                    <xsl:value-of select="string-join($app/mei:rdg[2]//@artic,', ')"/>
                                </em>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve')else('s')"/> no corresponding @artic</xsl:otherwise>
                        </xsl:choose>.
                        <xsl:if test="$app/mei:rdg[3]">Source<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('s ')else(' ')"/>
                            <xsl:sequence select="mei:resolveSources($app/mei:rdg[3]/@source)"/>
                            <xsl:choose>
                                <xsl:when test="$app/mei:rdg[3]//@artic"> read<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then(' ')else('s ')"/>
                                    <em>
                                        <xsl:value-of select="string-join($app/mei:rdg[3]//@artic,', ')"/>
                                    </em>
                                </xsl:when>
                                <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve')else('s')"/> no corresponding @artic</xsl:otherwise>
                            </xsl:choose>
                            .</xsl:if>
                    </p>
                </xsl:if>
                <xsl:if test="'dir' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">
                        Differing directives: Source<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[1]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[1]//mei:dir"> read<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then(' ')else('s ')"/> "<em>
                                    <xsl:apply-templates select="$app/mei:rdg[1]//mei:dir/node()"/>
                                </em>"</xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve')else('s')"/> no directive</xsl:otherwise>
                        </xsl:choose>, while source<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[2]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[2]//@artic"> read<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then(' ')else('s ')"/> "<em>
                                    <xsl:apply-templates select="$app/mei:rdg[1]//mei:dir/node()"/>
                                </em>"</xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve')else('s')"/> no corresponding directive</xsl:otherwise>
                        </xsl:choose>.
                    </p>
                </xsl:if>
                <xsl:if test="'dynam' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">
                        Differing dynamic instruction: Source<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[1]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[1]//mei:hairpin[@form = 'cres']"> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve ')else('s ')"/> a <em>crescendo</em> starting on timestamp <xsl:value-of select="$app/mei:rdg[1]//mei:hairpin[1]/@tstamp"/>
                                <xsl:value-of select="mei:resolveTstamp2($app/mei:rdg[1]//mei:hairpin[1]/@tstamp)"/>
                            </xsl:when>
                            <xsl:when test="$app/mei:rdg[1]//mei:hairpin[@form = 'dim']"> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve ')else('s ')"/> a <em>diminuendo</em> starting on timestamp <xsl:value-of select="$app/mei:rdg[1]//mei:hairpin[1]/@tstamp"/>
                                <xsl:value-of select="mei:resolveTstamp2($app/mei:rdg[1]//mei:hairpin[1]/@tstamp)"/>
                            </xsl:when>
                            <xsl:when test="$app/mei:rdg[1]//mei:dynam"> read<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then(' ')else('s ')"/>
                                <em>
                                    <xsl:apply-templates select="$app/mei:rdg[1]//mei:dynam/node()"/>
                                </em> on timestamp <xsl:value-of select="$app/mei:rdg[1]//mei:dynam[1]/@tstamp"/>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve')else('s')"/> no instruction</xsl:otherwise>
                        </xsl:choose>, while source<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[2]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[2]//mei:hairpin[@form = 'cres']"> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve ')else('s ')"/> a <em>crescendo</em> starting on timestamp <xsl:value-of select="$app/mei:rdg[2]//mei:hairpin[1]/@tstamp"/>
                                <xsl:value-of select="mei:resolveTstamp2($app/mei:rdg[2]//mei:hairpin[1]/@tstamp)"/>
                            </xsl:when>
                            <xsl:when test="$app/mei:rdg[2]//mei:hairpin[@form = 'dim']"> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve ')else('s ')"/> a <em>diminuendo</em> starting on timestamp <xsl:value-of select="$app/mei:rdg[2]//mei:hairpin[1]/@tstamp"/>
                                <xsl:value-of select="mei:resolveTstamp2($app/mei:rdg[2]//mei:hairpin[1]/@tstamp)"/>
                            </xsl:when>
                            <xsl:when test="$app/mei:rdg[2]//@artic"> read<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then(' ')else('s ')"/> "<em>
                                    <xsl:apply-templates select="$app/mei:rdg[2]//mei:dir/node()"/>
                                </em>"</xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve')else('s')"/> no corresponding instruction</xsl:otherwise>
                        </xsl:choose>.
                        <xsl:if test="$app/mei:rdg[3]">Source<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('s ')else(' ')"/>
                            <xsl:sequence select="mei:resolveSources($app/mei:rdg[3]/@source)"/>
                            <xsl:choose>
                                <xsl:when test="$app/mei:rdg[3]//mei:hairpin[@form = 'cres']"> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve ')else('s ')"/> a <em>crescendo</em> starting on timestamp <xsl:value-of select="$app/mei:rdg[3]//mei:hairpin[1]/@tstamp"/>
                                    <xsl:value-of select="mei:resolveTstamp2($app/mei:rdg[3]//mei:hairpin[1]/@tstamp)"/>
                                </xsl:when>
                                <xsl:when test="$app/mei:rdg[3]//mei:hairpin[@form = 'dim']"> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve ')else('s ')"/> a <em>diminuendo</em> starting on timestamp <xsl:value-of select="$app/mei:rdg[3]//mei:hairpin[1]/@tstamp"/>
                                    <xsl:value-of select="mei:resolveTstamp2($app/mei:rdg[3]//mei:hairpin[1]/@tstamp)"/>
                                </xsl:when>
                                <xsl:when test="$app/mei:rdg[3]//@artic"> read<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then(' ')else('s ')"/> "<em>
                                        <xsl:apply-templates select="$app/mei:rdg[3]//mei:dir/node()"/>
                                    </em>"</xsl:when>
                                <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve')else('s')"/> no corresponding instruction</xsl:otherwise>
                            </xsl:choose>
                            .</xsl:if>
                        <xsl:if test="$app/mei:rdg[4]">Source<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('s ')else(' ')"/>
                            <xsl:sequence select="mei:resolveSources($app/mei:rdg[4]/@source)"/>
                            <xsl:choose>
                                <xsl:when test="$app/mei:rdg[4]//mei:hairpin[@form = 'cres']"> ha<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('ve ')else('s ')"/> a <em>crescendo</em> starting on timestamp <xsl:value-of select="$app/mei:rdg[4]//mei:hairpin[1]/@tstamp"/>
                                    <xsl:value-of select="mei:resolveTstamp2($app/mei:rdg[4]//mei:hairpin[1]/@tstamp)"/>
                                </xsl:when>
                                <xsl:when test="$app/mei:rdg[4]//mei:hairpin[@form = 'dim']"> ha<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('ve ')else('s ')"/> a <em>diminuendo</em> starting on timestamp <xsl:value-of select="$app/mei:rdg[4]//mei:hairpin[1]/@tstamp"/>
                                    <xsl:value-of select="mei:resolveTstamp2($app/mei:rdg[4]//mei:hairpin[1]/@tstamp)"/>
                                </xsl:when>
                                <xsl:when test="$app/mei:rdg[4]//@artic"> read<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then(' ')else('s ')"/> "<em>
                                        <xsl:apply-templates select="$app/mei:rdg[4]//mei:dir/node()"/>
                                    </em>"</xsl:when>
                                <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('ve')else('s')"/> no corresponding instruction</xsl:otherwise>
                            </xsl:choose>
                            .</xsl:if>
                    </p>
                </xsl:if>
                <xsl:if test="'slur' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">
                        Different slurs: Source<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[1]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[1]//mei:slur"> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve ')else('s ')"/> a slur from <xsl:value-of select="$app/mei:rdg[1]//mei:slur[1]/@startid"/> to <xsl:value-of select="$app/mei:rdg[1]//mei:slur[1]/@endid"/>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve')else('s')"/> no slur</xsl:otherwise>
                        </xsl:choose>, while source<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[2]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[2]//mei:slur"> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve ')else('s ')"/> a slur from <xsl:value-of select="$app/mei:rdg[2]//mei:slur[1]/@startid"/> to <xsl:value-of select="$app/mei:rdg[2]//mei:slur[1]/@endid"/>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve')else('s')"/> no corresponding instruction</xsl:otherwise>
                        </xsl:choose>.
                        <xsl:if test="$app/mei:rdg[3]">Source<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('s ')else(' ')"/>
                            <xsl:sequence select="mei:resolveSources($app/mei:rdg[3]/@source)"/>
                            <xsl:choose>
                                <xsl:when test="$app/mei:rdg[3]//mei:slur"> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve ')else('s ')"/> a slur from <xsl:value-of select="$app/mei:rdg[3]//mei:slur[1]/@startid"/> to <xsl:value-of select="$app/mei:rdg[3]//mei:slur[1]/@endid"/>
                                </xsl:when>
                                <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve')else('s')"/> no corresponding instruction</xsl:otherwise>
                            </xsl:choose>
                            .</xsl:if>
                        <xsl:if test="$app/mei:rdg[4]">Source<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('s ')else(' ')"/>
                            <xsl:sequence select="mei:resolveSources($app/mei:rdg[4]/@source)"/>
                            <xsl:choose>
                                <xsl:when test="$app/mei:rdg[4]//mei:slur"> ha<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('ve ')else('s ')"/> a slur from <xsl:value-of select="$app/mei:rdg[4]//mei:slur[1]/@startid"/> to <xsl:value-of select="$app/mei:rdg[4]//mei:slur[1]/@endid"/>
                                </xsl:when>
                                <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('ve')else('s')"/> no corresponding instruction</xsl:otherwise>
                            </xsl:choose>
                            .</xsl:if>
                    </p>
                </xsl:if>
                <xsl:if test="'pitch' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">Different pitches.</p>
                </xsl:if>
                <xsl:if test="'dur' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">Different rhythmic disposition.</p>
                </xsl:if>
                <xsl:if test="'tie' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">
                        Different ties: Source<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[1]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[1]//@tie[. = 'i']"> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve ')else('s ')"/> a tie starting on timestamp <xsl:value-of select="$app/mei:rdg[1]//mei:*[@tie = 'i'][1]/@tstamp"/>
                            </xsl:when>
                            <xsl:when test="$app/mei:rdg[1]//@tie[. = 'm']"> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve ')else('s ')"/> a tie continuing on timestamp <xsl:value-of select="$app/mei:rdg[1]//mei:*[@tie = 'm'][1]/@tstamp"/>
                            </xsl:when>
                            <xsl:when test="$app/mei:rdg[1]//@tie[. = 't']"> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve ')else('s ')"/> a tie ending on timestamp <xsl:value-of select="$app/mei:rdg[1]//mei:*[@tie = 't'][1]/@tstamp"/>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve')else('s')"/> no tie</xsl:otherwise>
                        </xsl:choose>, while source<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[2]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[2]//@tie[. = 'i']"> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve ')else('s ')"/> a tie starting on timestamp <xsl:value-of select="$app/mei:rdg[2]//mei:*[@tie = 'i'][1]/@tstamp"/>
                            </xsl:when>
                            <xsl:when test="$app/mei:rdg[2]//@tie[. = 'm']"> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve ')else('s ')"/> a tie continuing on timestamp <xsl:value-of select="$app/mei:rdg[2]//mei:*[@tie = 'm'][1]/@tstamp"/>
                            </xsl:when>
                            <xsl:when test="$app/mei:rdg[2]//@tie[. = 't']"> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve ')else('s ')"/> a tie ending on timestamp <xsl:value-of select="$app/mei:rdg[2]//mei:*[@tie = 't'][1]/@tstamp"/>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve')else('s')"/> no corresponding tie</xsl:otherwise>
                        </xsl:choose>.
                        <xsl:if test="$app/mei:rdg[3]">Source<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('s ')else(' ')"/>
                            <xsl:sequence select="mei:resolveSources($app/mei:rdg[3]/@source)"/>
                            <xsl:choose>
                                <xsl:when test="$app/mei:rdg[3]//@tie[. = 'i']"> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve ')else('s ')"/> a tie starting on timestamp <xsl:value-of select="$app/mei:rdg[3]//mei:*[@tie = 'i'][1]/@tstamp"/>
                                </xsl:when>
                                <xsl:when test="$app/mei:rdg[3]//@tie[. = 'm']"> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve ')else('s ')"/> a tie continuing on timestamp <xsl:value-of select="$app/mei:rdg[3]//mei:*[@tie = 'm'][1]/@tstamp"/>
                                </xsl:when>
                                <xsl:when test="$app/mei:rdg[3]//@tie[. = 't']"> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve ')else('s ')"/> a tie ending on timestamp <xsl:value-of select="$app/mei:rdg[3]//mei:*[@tie = 't'][1]/@tstamp"/>
                                </xsl:when>
                                <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve')else('s')"/> no corresponding tie</xsl:otherwise>
                            </xsl:choose>
                            .</xsl:if>
                        <xsl:if test="$app/mei:rdg[4]">Source<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('s ')else(' ')"/>
                            <xsl:sequence select="mei:resolveSources($app/mei:rdg[4]/@source)"/>
                            <xsl:choose>
                                <xsl:when test="$app/mei:rdg[4]//@tie[. = 'i']"> ha<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('ve ')else('s ')"/> a tie starting on timestamp <xsl:value-of select="$app/mei:rdg[4]//mei:*[@tie = 'i'][1]/@tstamp"/>
                                </xsl:when>
                                <xsl:when test="$app/mei:rdg[4]//@tie[. = 'm']"> ha<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('ve ')else('s ')"/> a tie continuing on timestamp <xsl:value-of select="$app/mei:rdg[4]//mei:*[@tie = 'm'][1]/@tstamp"/>
                                </xsl:when>
                                <xsl:when test="$app/mei:rdg[4]//@tie[. = 't']"> ha<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('ve ')else('s ')"/> a tie ending on timestamp <xsl:value-of select="$app/mei:rdg[4]//mei:*[@tie = 't'][1]/@tstamp"/>
                                </xsl:when>
                                <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[4]/@source,' '))then('ve')else('s')"/> no corresponding tie</xsl:otherwise>
                            </xsl:choose>
                            .</xsl:if>
                    </p>
                </xsl:if>
                <xsl:if test="'accid' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">
                        Accidentals: Source<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[1]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[1]//@accid"> read<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then(' ')else('s ')"/>
                                <em>
                                    <xsl:value-of select="string-join($app/mei:rdg[1]//@accid,', ')"/>
                                </em>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve')else('s')"/> no @accid</xsl:otherwise>
                        </xsl:choose>, while source<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[2]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[2]//@accid"> read<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then(' ')else('s ')"/>
                                <em>
                                    <xsl:value-of select="string-join($app/mei:rdg[2]//@accid,', ')"/>
                                </em>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve')else('s')"/> no corresponding @accid</xsl:otherwise>
                        </xsl:choose>.
                        <xsl:if test="$app/mei:rdg[3]">Source<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('s ')else(' ')"/>
                            <xsl:sequence select="mei:resolveSources($app/mei:rdg[3]/@source)"/>
                            <xsl:choose>
                                <xsl:when test="$app/mei:rdg[3]//@accid"> read<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then(' ')else('s ')"/>
                                    <em>
                                        <xsl:value-of select="string-join($app/mei:rdg[3]//@accid,', ')"/>
                                    </em>
                                </xsl:when>
                                <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[3]/@source,' '))then('ve')else('s')"/> no corresponding @accid</xsl:otherwise>
                            </xsl:choose>
                            .</xsl:if>
                    </p>
                </xsl:if>
                <xsl:if test="'clef' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">
                        Slurs: Source<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[1]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[1]//mei:clef"> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve ')else('s ')"/> a <xsl:value-of select="($app/mei:rdg[1]//mei:clef)[1]/@shape"/> clef at timestamp <xsl:value-of select="($app/mei:rdg[1]//mei:clef)[1]/@tstamp"/>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve')else('s')"/> no clef</xsl:otherwise>
                        </xsl:choose>, while source<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[2]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[2]//mei:clef"> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve ')else('s ')"/> a <xsl:value-of select="($app/mei:rdg[2]//mei:clef)[1]/@shape"/> clef at timestamp <xsl:value-of select="($app/mei:rdg[2]//mei:clef)[1]/@tstamp"/>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve')else('s')"/> no corresponding clef</xsl:otherwise>
                        </xsl:choose>.
                    </p>
                </xsl:if>
                <xsl:if test="'voicing' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">Additional layer in some sources.</p>
                </xsl:if>
                <xsl:if test="'notation' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">Notational differences</p>
                </xsl:if>
                <xsl:if test="'fermata' = $decls">
                    <p xmlns="http://www.w3.org/1999/xhtml">
                        Fermata: Source<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[1]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[1]//@fermata"> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve ')else('s ')"/> a fermata at timestamp <xsl:value-of select="($app/mei:rdg[1]//mei:*[@fermata])[1]/@tstamp"/>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[1]/@source,' '))then('ve')else('s')"/> no fermata</xsl:otherwise>
                        </xsl:choose>, while source<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('s ')else(' ')"/>
                        <xsl:sequence select="mei:resolveSources($app/mei:rdg[2]/@source)"/>
                        <xsl:choose>
                            <xsl:when test="$app/mei:rdg[2]/@fermata"> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve ')else('s ')"/> a fermata at timestamp <xsl:value-of select="($app/mei:rdg[2]//mei:*[@fermata])[1]/@tstamp"/>
                            </xsl:when>
                            <xsl:otherwise> ha<xsl:value-of select="if(contains($app/mei:rdg[2]/@source,' '))then('ve')else('s')"/> no corresponding fermata</xsl:otherwise>
                        </xsl:choose>.
                    </p>
                </xsl:if>
                <p xmlns="http://www.w3.org/1999/xhtml">Annotation text generated based on encoding.</p>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:p">
        <p xmlns="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates select="node() | @*"/>
        </p>
    </xsl:template>
    <xsl:template match="mei:quote">
        <span xmlns="http://www.w3.org/1999/xhtml" class="annotQuote">
            <xsl:apply-templates select="node() | @*"/>
        </span>
    </xsl:template>
    <xsl:template match="mei:ref">
        <span xmlns="http://www.w3.org/1999/xhtml" class="ref">
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>
    <xsl:template match="mei:ptr">
        <xsl:sequence select="mei:resolveSources(@target)"/>
    </xsl:template>
    <xsl:template match="mei:rend">
        <xsl:choose>
            <xsl:when test="@rend = 'italic'">
                <em xmlns="http://www.w3.org/1999/xhtml">
                    <xsl:apply-templates select="node()"/>
                </em>
            </xsl:when>
            <xsl:when test="@rend = 'underline'">
                <u xmlns="http://www.w3.org/1999/xhtml">
                    <xsl:apply-templates select="node()"/>
                </u>
            </xsl:when>
            <xsl:when test="@rend = 'latintype'">
                <span xmlns="http://www.w3.org/1999/xhtml" class="annotLatinType">
                    <xsl:apply-templates select="node()"/>
                </span>
            </xsl:when>
            <xsl:when test="@rend = 'superscript'">
                <sup xmlns="http://www.w3.org/1999/xhtml">
                    <xsl:apply-templates select="node()"/>
                </sup>
            </xsl:when>
            <xsl:otherwise>
                <span xmlns="http://www.w3.org/1999/xhtml" class="otherRend">
                    <xsl:apply-templates select="node()"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="node()">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>