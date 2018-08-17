pragma solidity 		^0.4.21	;						
										
	contract	SEAPORT_Portfolio_VII_883				{				
										
		mapping (address =&gt; uint256) public balanceOf;								
										
		string	public		name =	&quot;	SEAPORT_Portfolio_VII_883		&quot;	;
		string	public		symbol =	&quot;	SEAPORT883VII		&quot;	;
		uint8	public		decimals =		18			;
										
		uint256 public totalSupply =		831660039583872000000000000					;	
										
		event Transfer(address indexed from, address indexed to, uint256 value);								
										
		function SimpleERC20Token() public {								
			balanceOf[msg.sender] = totalSupply;							
			emit Transfer(address(0), msg.sender, totalSupply);							
		}								
										
		function transfer(address to, uint256 value) public returns (bool success) {								
			require(balanceOf[msg.sender] &gt;= value);							
										
			balanceOf[msg.sender] -= value;  // deduct from sender&#39;s balance							
			balanceOf[to] += value;          // add to recipient&#39;s balance							
			emit Transfer(msg.sender, to, value);							
			return true;							
		}								
										
		event Approval(address indexed owner, address indexed spender, uint256 value);								
										
		mapping(address =&gt; mapping(address =&gt; uint256)) public allowance;								
										
		function approve(address spender, uint256 value)								
			public							
			returns (bool success)							
		{								
			allowance[msg.sender][spender] = value;							
			emit Approval(msg.sender, spender, value);							
			return true;							
		}								
										
		function transferFrom(address from, address to, uint256 value)								
			public							
			returns (bool success)							
		{								
			require(value &lt;= balanceOf[from]);							
			require(value &lt;= allowance[from][msg.sender]);							
										
			balanceOf[from] -= value;							
			balanceOf[to] += value;							
			allowance[from][msg.sender] -= value;							
			emit Transfer(from, to, value);							
			return true;							
		}								
//	}									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	// Programme d&#39;&#233;mission - Lignes 1 &#224; 10									
	//									
	//									
	//									
	//									
	//     [ Nom du portefeuille ; Num&#233;ro de la ligne ; Nom de la ligne ; Ech&#233;ance ]									
	//         [ Adresse export&#233;e ]									
	//         [ Unit&#233; ; Limite basse ; Limite haute ]									
	//         [ Hex ]									
	//									
	//									
	//									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_1_____Novorossiysk Port of Novorossiysk_Port_Spe_Value_20230515 &gt;									
	//        &lt; a4767VTR3x9A4bC0FphnCmOyY8JSnYgoKvHDW78uEd6VRKEFw2xmw009r9J0Hy5b &gt;									
	//        &lt; 1E-018 limites [ 1E-018 ; 21856728,6061468 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000000000000008246BA90 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_2_____Novorossiysk_Port_Spe_Value_20230515 &gt;									
	//        &lt; W22SwHleW8b0Izq88BlL1G6p584dc65RuC0M1vz8II311t8Qu7fj0eHL8QEZlMk8 &gt;									
	//        &lt; 1E-018 limites [ 21856728,6061468 ; 50306307,7954406 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000008246BA9012BD9576F &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_3_____Novosibirsk_Port_Spe_Value_20230515 &gt;									
	//        &lt; qflz7L412r5bC2h51RVQBuKlM4hIdhSl61FxgJ23IX3n3H9k7GmgtR6W7T713vwE &gt;									
	//        &lt; 1E-018 limites [ 50306307,7954406 ; 65899592,0380108 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000012BD9576F188CACE17 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_4_____Olga_Port_Authority_20230515 &gt;									
	//        &lt; WVhtTL79oeTCzQlXHc6y419k884n0dTa2v0Ks2gC071g8WlNdN3Y7dZFk8C66cK0 &gt;									
	//        &lt; 1E-018 limites [ 65899592,0380108 ; 81408748,4855109 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000188CACE171E53BE654 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_5_____Olga_Port_Authority_20230515 &gt;									
	//        &lt; p2SWS701m7q44sXHYH5XS4W43LXDmsE5124xY0h8y93y1lIiS6o2b51xkd3cVmal &gt;									
	//        &lt; 1E-018 limites [ 81408748,4855109 ; 96323880,8191582 ] &gt;									
	//        &lt; 0x00000000000000000000000000000000000000000000001E53BE65423E2295E5 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_6_____Omsk_Port_Spe_Value_20230515 &gt;									
	//        &lt; 8s4AJ0567uy40hX7d2FEF0MKeWUoMw5WZ5F3n5BS5rjljKl93wl7QQU70BF4Dn4u &gt;									
	//        &lt; 1E-018 limites [ 96323880,8191582 ; 118094022,026032 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000023E2295E52BFE52F4E &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_7_____Onega Port of Onega_Port_Spe_Value_20230515 &gt;									
	//        &lt; vi4BQiM1x32Lh0PJY6jg9TQ46IYc47DTKnfzn194JQnPuXw98b8LCG7Eh98Uw0w2 &gt;									
	//        &lt; 1E-018 limites [ 118094022,026032 ; 138307730,940671 ] &gt;									
	//        &lt; 0x00000000000000000000000000000000000000000000002BFE52F4E33860DB5A &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_8_____Onega_Port_Authority_20230515 &gt;									
	//        &lt; Z81nJgH6pRkG7VkaiX61hnb1R5HS759Q2k4DT8nje88z1Jh5MUQjK2iq94s0oYop &gt;									
	//        &lt; 1E-018 limites [ 138307730,940671 ; 163089132,802004 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000033860DB5A3CC164674 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_9_____Onega_Port_Authority_20230515 &gt;									
	//        &lt; 7rt9rb62nIdwgr4s4DVv3mSR6w37hNl9d3Ez6T2f0K7te9Nai0f300K4H2Vt9L9n &gt;									
	//        &lt; 1E-018 limites [ 163089132,802004 ; 188060620,049932 ] &gt;									
	//        &lt; 0x00000000000000000000000000000000000000000000003CC164674460EDBDA8 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_10_____Perm_Port_Spe_Value_20230515 &gt;									
	//        &lt; dLAjvq95O8Nwt263Eeo8yiWqFF3i9qS50F45B3Ipm0u77EkYLE6Sq91hTiaNNe1c &gt;									
	//        &lt; 1E-018 limites [ 188060620,049932 ; 209312617,242435 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000460EDBDA84DF99B710 &gt;									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	// Programme d&#39;&#233;mission - Lignes 11 &#224; 20									
	//									
	//									
	//									
	//									
	//     [ Nom du portefeuille ; Num&#233;ro de la ligne ; Nom de la ligne ; Ech&#233;ance ]									
	//         [ Adresse export&#233;e ]									
	//         [ Unit&#233; ; Limite basse ; Limite haute ]									
	//         [ Hex ]									
	//									
	//									
	//									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_11_____Petropavlovsk_Kamchatskiy_Port_Spe_Value_20230515 &gt;									
	//        &lt; Z0W1Zn1UpeJlv2J5qZpndoozFPUcNH9w788ruCssIu7dVqa9J8oF54anOd6B58IF &gt;									
	//        &lt; 1E-018 limites [ 209312617,242435 ; 232541937,723194 ] &gt;									
	//        &lt; 0x00000000000000000000000000000000000000000000004DF99B71056A0ED860 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_12_____Petropavlovsk_Kamchatsky Port of Petropavlovsk_Kamchatsky_Port_Spe_Value_20230515 &gt;									
	//        &lt; 7Q7tL2tRz7V7rK1jSHMWfof6OKhBt93TJpMOM1k1ci6Hr0gC6wdaoh0DLfpUVQQR &gt;									
	//        &lt; 1E-018 limites [ 232541937,723194 ; 250320165,082122 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000056A0ED8605D4064470 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_13_____Pevek Port of Pevek_Port_Spe_Value_20230515 &gt;									
	//        &lt; lM0URV9T165xq9i399aWCUA2CmFV1xUKhiYw49r8m6R73gc0auTz0frc84grVBk4 &gt;									
	//        &lt; 1E-018 limites [ 250320165,082122 ; 266613342,483114 ] &gt;									
	//        &lt; 0x00000000000000000000000000000000000000000000005D406447063523AEDC &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_14_____Poronaysk Port of Poronaysk_Port_Spe_Value_20230515 &gt;									
	//        &lt; IGdGhCI30bxSTk8h67qk3TrQOKpPgyvqQf50vV3BW34P1fST0ja9H0jL2bSyCM3l &gt;									
	//        &lt; 1E-018 limites [ 266613342,483114 ; 292395631,853538 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000063523AEDC6CED055A5 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_15_____Poronaysk_Port_Authority_20230515 &gt;									
	//        &lt; w5Ixsp0Fn766S1Dg72s5LZBUx9fRqO2ZAxMqPe3RtF9H22YGvXf7Amw3N15oq5I5 &gt;									
	//        &lt; 1E-018 limites [ 292395631,853538 ; 307938190,387152 ] &gt;									
	//        &lt; 0x00000000000000000000000000000000000000000000006CED055A572B746592 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_16_____Poronaysk_Port_Authority_20230515 &gt;									
	//        &lt; 1V0W8K06fgUeSog7P5igR39Vtics3hpqdiNwK271q1636Cq0B8mHMj9KkQ7FQc3H &gt;									
	//        &lt; 1E-018 limites [ 307938190,387152 ; 328597011,374162 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000072B7465927A6974185 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_17_____Port_Authority_of_St_Petersburg_20230515 &gt;									
	//        &lt; 56L5oIjhS92Vo6TG81JY3OsB9N3g43S5kaIRH17QmS060UVX9ndux59F6g9gK3S9 &gt;									
	//        &lt; 1E-018 limites [ 328597011,374162 ; 351529374,981334 ] &gt;									
	//        &lt; 0x00000000000000000000000000000000000000000000007A697418582F47440E &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_18_____Port_Authority_of_St_Petersburg_20230515 &gt;									
	//        &lt; i6mgr4X98mc9kaw2hYVesiWZAO9DXapfWs9fic2h7puq1t2zi39GT0IG693z5aTD &gt;									
	//        &lt; 1E-018 limites [ 351529374,981334 ; 367758983,166911 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000082F47440E89003AEC0 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_19_____Posyet Port of Posyet_Port_Spe_Value_20230515 &gt;									
	//        &lt; 0IU9pLicZ7700v2ojnJP1ige2K998CHOx4hc237wTn0jQf3I0ETc2y96dg7FY39P &gt;									
	//        &lt; 1E-018 limites [ 367758983,166911 ; 394365940,535429 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000089003AEC092E9AAD79 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_20_____Primorsk Port of Primorsk_Port_Spe_Value_20230515 &gt;									
	//        &lt; b0cOUQ91ytt05KBesDzV6tpTuEL5FBq8n1RI8363V7I6lXlc9wbEXnruAs2Ya6bu &gt;									
	//        &lt; 1E-018 limites [ 394365940,535429 ; 413157508,198651 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000092E9AAD7999E9C5597 &gt;									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	// Programme d&#39;&#233;mission - Lignes 21 &#224; 30									
	//									
	//									
	//									
	//									
	//     [ Nom du portefeuille ; Num&#233;ro de la ligne ; Nom de la ligne ; Ech&#233;ance ]									
	//         [ Adresse export&#233;e ]									
	//         [ Unit&#233; ; Limite basse ; Limite haute ]									
	//         [ Hex ]									
	//									
	//									
	//									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_21_____Primorsk_Port_Authority_20230515 &gt;									
	//        &lt; CS5m3U474NTI7Wv4bJAJnxFT78I4Eam3VUDW9M5QQ4e5u6QFS3mHT4Da52OCl2KI &gt;									
	//        &lt; 1E-018 limites [ 413157508,198651 ; 430858723,09083 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000099E9C5597A081E3EA9 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_22_____Providenija Port of Providenija_Port_Spe_Value_20230515 &gt;									
	//        &lt; 0DCU7Gld08JOOs0oxK3hO1344Jjrt2b6N2VA2EZBkHw7ruE4AX3QTOVCgzG97X5I &gt;									
	//        &lt; 1E-018 limites [ 430858723,09083 ; 449919869,657276 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000A081E3EA9A79BB3F09 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_23_____Rostov_on_Don Port of Rostov_on_Don_Port_Spe_Value_20230515 &gt;									
	//        &lt; 1P16E21OHmR4EwGCMojvH0gm56dNYFvmp8FdUoqxuCY7FQ28Yx67QNZ5J2ehx933 &gt;									
	//        &lt; 1E-018 limites [ 449919869,657276 ; 468278197,328073 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000A79BB3F09AE727D4C8 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_24_____Rostov_on_Don_Port_Spe_Value_20230515 &gt;									
	//        &lt; 1k0hmZ6a9G1eqk9QZG0inpM9z70Bb4OUMr796GlTJaPrwvLI95v98vf6QOSmPepV &gt;									
	//        &lt; 1E-018 limites [ 468278197,328073 ; 489414703,320786 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000AE727D4C8B65239470 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_25_____Ryazan_Port_Spe_Value_20230515 &gt;									
	//        &lt; E2oSXi32DF2L21FJ1KiZzHn8FvLI0H4Nymz54DaKs3SPVD7332MAfc1y5X2iKv88 &gt;									
	//        &lt; 1E-018 limites [ 489414703,320786 ; 507850330,152042 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000B65239470BD3061D2B &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_26_____Saint Petersburg Port of Saint Petersburg_Port_Spe_Value_20230515 &gt;									
	//        &lt; bL727R3kzgWeZGQo1PYp2uTDeh1T02hw7lW3bhKSaDExaG95vkx6vbD9kJ0T0Ltu &gt;									
	//        &lt; 1E-018 limites [ 507850330,152042 ; 533519909,795645 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000BD3061D2BC6C06C8B7 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_27_____Salekhard_Port_Spe_Value_20230515 &gt;									
	//        &lt; Yo3WYvX1B2L6GU56Umi7Jl8E4gH37p4g4C6nks5o7IWWxZ0ul4Pk2czHdLZ0Qo59 &gt;									
	//        &lt; 1E-018 limites [ 533519909,795645 ; 560105200,261919 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000C6C06C8B7D0A7CB7CE &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_28_____Samara_Port_Spe_Value_20230515 &gt;									
	//        &lt; 85oN7x8ZxQMwcgbMR08eaF7fX8W6dGOr8069I5r2H23819Gvc0LZqBAk61lM4rM4 &gt;									
	//        &lt; 1E-018 limites [ 560105200,261919 ; 588224726,320107 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000D0A7CB7CEDB217B5AC &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_29_____Saratov_Port_Spe_Value_20230515 &gt;									
	//        &lt; V0i2U8Ki1Id9I1wNlPe6fK5hWeLA2BuMkn9407OLS8bN3T243Q2RH01AZ24yTqMF &gt;									
	//        &lt; 1E-018 limites [ 588224726,320107 ; 603091217,912931 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000DB217B5ACE0AB42CF3 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_30_____Sarepta_Port_Spe_Value_20230515 &gt;									
	//        &lt; eDcOD7wpgXcC4t1S7W69r8g838H5BB00Q381zEIAG4h7x9Kf1k48I9radZml0zM5 &gt;									
	//        &lt; 1E-018 limites [ 603091217,912931 ; 625771450,288981 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000E0AB42CF3E91E376B8 &gt;									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	// Programme d&#39;&#233;mission - Lignes 31 &#224; 40									
	//									
	//									
	//									
	//									
	//     [ Nom du portefeuille ; Num&#233;ro de la ligne ; Nom de la ligne ; Ech&#233;ance ]									
	//         [ Adresse export&#233;e ]									
	//         [ Unit&#233; ; Limite basse ; Limite haute ]									
	//         [ Hex ]									
	//									
	//									
	//									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_31_____Sea_Port_Hatanga_20230515 &gt;									
	//        &lt; l1AcUyHV15n4eAVB4F0PTH8eY7Z0Yz8myHt5mTD4XX117RfPycEUsQbe8ek2K1it &gt;									
	//        &lt; 1E-018 limites [ 625771450,288981 ; 645935703,401499 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000E91E376B8F0A13AC18 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_32_____Sea_Port_Zarubino_20230515 &gt;									
	//        &lt; hvvLX226yn2JUB1HH787S9J8U7p11T1Tm2733aMFhe7o210sL6Z5BhP2VQ9CJ3DA &gt;									
	//        &lt; 1E-018 limites [ 645935703,401499 ; 667753217,080227 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000000F0A13AC18F8C1E8E60 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_33_____Serpukhov_Port_Spe_Value_20230515 &gt;									
	//        &lt; 29Adz5FkJSKHTR9K512XHqP048817ksCGbwfm9h5zGNZle4eFhhWd61G96pG8z9W &gt;									
	//        &lt; 1E-018 limites [ 667753217,080227 ; 688826896,09959 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000000F8C1E8E601009BA703D &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_34_____Sevastopol_Marine_Trade_Port_20230515 &gt;									
	//        &lt; 4f0I7f71sjyS5nrH6zGhcjMF5GFcxcsBxZRJLnwg9GUmHO8I066tPNX2DScztvv2 &gt;									
	//        &lt; 1E-018 limites [ 688826896,09959 ; 703823462,631833 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000001009BA703D10631D620B &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_35_____Sevastopol_Port_Spe_Value_20230515 &gt;									
	//        &lt; 4h8AG71H0R2s2P1jvGV7x2qMB29rzO80d9Abj098nH80P46Ceb15Op66AwjP483O &gt;									
	//        &lt; 1E-018 limites [ 703823462,631833 ; 724799539,220132 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000010631D620B10E02455F6 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_36_____Severodvinsk_Port_Spe_Value_20230515 &gt;									
	//        &lt; 9995Hf928BXZe5Gh6iufi6UYfiBJPX5H7910dsw21pSrqnHEDO12mwVdz3tlm863 &gt;									
	//        &lt; 1E-018 limites [ 724799539,220132 ;  ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000010E02455F611808D7743 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_37_____Sochi Port of Sochi_Port_Spe_Value_20230515 &gt;									
	//        &lt; JZ0TZ4925wdBK91cfXe0Wd7oOS2QXTHeYxQTv4tx779Mfa0Mgho65zNo7qSnIvR1 &gt;									
	//        &lt; 1E-018 limites [ 751711982,87324 ; 771591961,494733 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000011808D774311F70BE7E9 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_38_____Sochi_Port_Authority_20230515 &gt;									
	//        &lt; ID0LIQ7f8Nn3t906Pk9dkXD1Pj9gI1o75ihcWYEp4Aq3uvB6EqB716mSH4Xqt4Kt &gt;									
	//        &lt; 1E-018 limites [ 771591961,494733 ; 797186023,890109 ] &gt;									
	//        &lt; 0x0000000000000000000000000000000000000000000011F70BE7E9128F995889 &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_39_____Sochi_Port_Spe_Value_20230515 &gt;									
	//        &lt; tXn54eD5tYoIXpWQv43AkY343TQ0k0QwS60J6UO41l42UAeKBW2ZcZxz0OuBTfpV &gt;									
	//        &lt; 1E-018 limites [ 797186023,890109 ; 816321780,430821 ] &gt;									
	//        &lt; 0x00000000000000000000000000000000000000000000128F9958891301A8316F &gt;									
	//     &lt; SEAPORT_Portfolio_VII_metadata_line_40_____Solombala_Port_Spe_Value_20230515 &gt;									
	//        &lt; 1YLgFQ0yJ3hz1w3i65gAVG910dHcWcDeBlFdN74mI9MA695AR3cqTCNLMExuu07K &gt;									
	//        &lt; 1E-018 limites [ 816321780,430821 ; 831660039,583872 ] &gt;									
	//        &lt; 0x000000000000000000000000000000000000000000001301A8316F135D1484EA &gt;									
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
										
	}