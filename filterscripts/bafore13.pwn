/*
	Bafore13 System(Sistema de Cigarros)
		- Bafore13 é a nova marca de cigarros do mercado. Com um novo
		design, Bafore13 se torna uma maneira prática e interessante
		de se usufruir de cigarros no mundo do SA-MP, usando recursos
		de TextDraw clicáveis, nunca foi tão diferente carburar um
		tabaco.

		Versão: 1.0.0
		Última atualização: 05/09/16

	Copyright (C) 2016  Bruno Travi(Bruno13)

	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

	Esqueleto do código:
	|
	 *
	 * INCLUDES
	 *
	|
	 *
	 * DEFINITIONS
	 *
	|
	 *
	 * ENUMERATORS
	 *
	|
	 *
	 * VARIABLES
	 *
	|
	 *
	 * NATIVE CALLBACKS
	 *
	|
	 *
	 * MY CALLBACKS
	 *
	|
	 *
	 * FUNCTIONS
	 *
	|
	 *
	 * COMPLEMENTS
	 *
	|
	 *
	 * COMMANDS
	 *
	|
*/
/*
 |INCLUDES|
*/
#include <a_samp>
#include <zcmd>
#include <sscanf2>
#include <a_mysql>
/*
 *****************************************************************************
*/
/*
 |DEFINITIONS|
*/
//MACROS:
stock stringf[256];
#define SendClientMessageEx(%0,%1,%2,%3) format(stringf, sizeof(stringf),%2,%3) && SendClientMessage(%0, %1, stringf)
#define call:%0(%1) forward %0(%1); public %0(%1)

//DEFINITIONS:
new const 
	mysql_host[]				= "localhost",
	mysql_user[]				= "user",
	mysql_password[]			= "password",
	mysql_database[]			= "database",

	CIGARETTE_ACCESS_IF_HAVE	=	false,
	CIGARETTE_PUFF				=	6;
/*
 *****************************************************************************
*/
/*
 |ENUMERATORS|
*/
const 
	size_E_CIGARETTE	= 	5 * 13,
	COLOR_RED			=	0xE84F33AA,
	COLOR_GREEN			=	0x9ACD32AA,
	COLOR_YELLOW		=	0xFCD440AA,

	CIGARETTE_PACKAGE_FULL		=	5;

enum E_TEXT_BAFORE_13
{
	Text:E_BOX[16],
	Text:E_LID_BOX[4],
	Text:E_LID_BOX_CLICK,
	Text:E_CIGARETTE[size_E_CIGARETTE],
	Text:E_CIGARETTE_CLICK[5]
}

#define E_CIGARETTE][%1][%2] E_CIGARETTE][((%1)*13)+(%2)]

enum E_CIGARETTE_PLAYER
{
	bool:E_HAVE_CIGARETTE[5],
	bool:E_PACKAGE_OPENED,
	bool:E_SMOKING_CIGARETTE,
	E_COUNT_PUFF_CIGARETTE,
	E_TIME_PUFF_CONTROL,
	E_TIMER_DURATION
}
/*
 *****************************************************************************
*/
/*
 |VARIABLES|
*/
new 
	/// <summary> 
	///	Variáveis de controle das TextDraws Globais.</summary>
	Text:textBafore13[E_TEXT_BAFORE_13],

	/// <summary> 
	///	Variável de controle dos cigarros do player.</summary>
	cigarettePlayer[MAX_PLAYERS][E_CIGARETTE_PLAYER],

	/// <summary> 
	///	Variável para armazenar query a ser executada por funções MySQL.</summary>
	myQuery[500],

	/// <summary> 
	///	Variável para armazenar o identificador de conexão MySQL.</summary>
	MySQL:mySQL;
/*
 *****************************************************************************
*/
/*
 |NATIVE CALLBACKS|
*/
public OnFilterScriptInit()
{
	/// <summary>
	/// Nesta callback:
	///		- faz a conexão com o servidor MySQL;
	///		- verifica e cria a tabela utilizada se não existir;
	///		- cria todas as TextDraws Globias da caixa de cigarros;
	///		- imprime aviso de carregamento no console.
	/// </summary>

	mysql_log(ALL);

	MySQL_Connect();

	MySQL_CheckTable();

    CreateGlobalTDBafore13();

	print("\n----------------------------------------");
	print("      [B13] Bafore13 System loaded");
	print("      * version 1.0.0");
	print("----------------------------------------\n");

	return 1;
}

public OnFilterScriptExit()
{
	/// <summary>
	/// Nesta callback:
	///		- finaliza a conexão com o servidor MySQL.
	/// </summary>

    MySQL_Disconnect();

    return 1;
}

public OnPlayerConnect(playerid)
{
	/// <summary>
	/// Nesta callback:
	///		- reseta a variável de controle dos cigarros do jogador;
	///		- carrega os cigarros do jogador.
	/// </summary>

	ResetPlayerCigarretes(playerid);

	LoadPlayerCigarettes(playerid);

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	/// <summary>
	/// Nesta callback:
	///		- salva os cigarros do jogador.
	/// </summary>

    SavePlayerCigarettes(playerid);

	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
	/// <summary>
	/// Nesta callback:
	///		- aplica as funções ao clique de cada TextDraw da caixa de cigarros.
	/// </summary>

	if(_:clickedid == INVALID_TEXT_DRAW)
	{
		HidePlayerCigarettePackage(playerid);
	}

	if(clickedid == textBafore13[E_LID_BOX_CLICK])
	{
		OpenCigaretteBox(playerid);
	}

	for(new i; i < 5; i++)
	{
		if(clickedid == textBafore13[E_CIGARETTE_CLICK][i])
		{
			if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) 
				return SendClientMessage(playerid, COLOR_RED, "<!> {FFFFFF}Você não pode fumar cigarro dentro de um veículo.");

			CancelSelectTextDraw(playerid);

		    HidePlayerCigarettePackage(playerid);

			SmokeCigarette(playerid, i);

			break;
		}
	}

	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	/// <summary>
	/// Nesta callback:
	///		- valida se o jogador em questão teclou KEY_FIRE para fumar, se sim aplica o controle sobre o cigarro em uso;
	///		- valida se o jogador teclou KEY_SECONDARY_ATTACK e está fumando cigarro, se sim apaga o cigarro em uso.
	/// </summary>

	if((newkeys & KEY_FIRE) && cigarettePlayer[playerid][E_SMOKING_CIGARETTE] && GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_SMOKE_CIGGY)
	{
	    if(gettime() - cigarettePlayer[playerid][E_TIME_PUFF_CONTROL] < 3) return 1;

        cigarettePlayer[playerid][E_TIME_PUFF_CONTROL] = gettime();

		cigarettePlayer[playerid][E_COUNT_PUFF_CIGARETTE]--;

		if(cigarettePlayer[playerid][E_COUNT_PUFF_CIGARETTE] < 1)
			SetTimerEx("CallLastCigarettePuff", 2700, false, "i", playerid);
	}

	if((newkeys & KEY_SECONDARY_ATTACK) && cigarettePlayer[playerid][E_SMOKING_CIGARETTE])
	{
	    ClearAnimations(playerid);

		SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);

		KillTimer(cigarettePlayer[playerid][E_TIMER_DURATION]);

		cigarettePlayer[playerid][E_SMOKING_CIGARETTE] = false;

		SendClientMessage(playerid, COLOR_YELLOW, "<!> {FFFFFF}Você apagou seu cigarro.");
	}
	
	return 1;
}

public OnQueryError(errorid, const error[], const callback[], const query[], MySQL:handle)
{
	if(errorid == 1146)
	{
		mysql_tquery(handle, "CREATE TABLE IF NOT EXISTS `bafore13`(`user` VARCHAR(24) NOT NULL, `cigarette0` BOOLEAN NOT NULL, `cigarette1` BOOLEAN NOT NULL, `cigarette2` BOOLEAN NOT NULL, `cigarette3` BOOLEAN NOT NULL, `cigarette4` BOOLEAN NOT NULL)", "MySQL_OnTableCreated", "s", "bafore13");
	}
	return 1;
}
/*
 *****************************************************************************
*/
/*
 |MY CALLBACKS|
*/
/// <summary>
/// Callback responsável por receber resposta do servidor MySQL
/// sobre a verificação da tabela.
/// Intervalo: -
/// </summary>
/// <param name="table">Nome da tabela criada.</param>
/// <returns>Não retorna valores.</returns>
call:MySQL_OnTableChecked(table[])
{
	printf("MySQL: Tabela '%s' encontrada.", table);
}
/// <summary>
/// Callback responsável por receber resposta do servidor MySQL
/// sobre a criação da tabela.
/// Intervalo: -
/// </summary>
/// <param name="table">Nome da tabela criada.</param>
/// <returns>Não retorna valores.</returns>
call:MySQL_OnTableCreated(table[])
{
	printf("MySQL: Tabela '%s' criada.", table);
}
/// <summary>
/// Callback responsável por receber resposta do servidor MySQL
/// sobre o carregamento dos cigarros de um jogador específico.
/// Intervalo: -
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Não retorna valores.</returns>
call:MySQL_OnPlayerCigarettesLoaded(playerid)
{
	if(cache_num_rows())
	{
		for(new i, item[11]; i < 5; i++)
		{
			format(item, 11, "cigarette%d", i);

			cache_get_value_name_int(0, item, cigarettePlayer[playerid][E_HAVE_CIGARETTE][i]);
		}
	}
	else
	{
		mysql_format(mySQL, myQuery, sizeof(myQuery), "INSERT INTO `bafore13` (`user`, `cigarette0`, `cigarette1`, `cigarette2`, `cigarette3`, `cigarette4`) VALUES ('%s', false, false, false, false, false)", GetNameOfPlayer(playerid));
		mysql_tquery(mySQL, myQuery, "MySQL_OnPlayerCigarettesCreated", "s", GetNameOfPlayer(playerid));
	}
}
/// <summary>
/// Callback responsável por receber resposta do servidor MySQL
/// sobre o salvamento dos cigarros de um jogador específico.
/// Intervalo: -
/// </summary>
/// <param name="playerName">Nome do jogador.</param>
/// <returns>Não retorna valores.</returns>
call:MySQL_OnPlayerCigarettesSaved(playerName[])
{
	printf("MySQL: Cigarros do jogador '%s' salvos.", playerName);
}
/// <summary>
/// Callback responsável por receber resposta do servidor MySQL
/// sobre a inserção de dados de um jogador específico na tabela.
/// Intervalo: -
/// </summary>
/// <param name="playerName">Nome do jogador.</param>
/// <returns>Não retorna valores.</returns>
call:MySQL_OnPlayerCigarettesCreated(playerName[])
{
	printf("MySQL: Cigarros do jogador '%s' criados na tabela.", playerName);
}
/// <summary>
/// Timer responsável por apagar o cigarro acendido por um jogador
/// específico em 1 min.
/// Intervalo: 60000ms
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Não retorna valores.</returns>
call:BurningCigarette(playerid)
{
	if(cigarettePlayer[playerid][E_SMOKING_CIGARETTE])
	{
		SendClientMessage(playerid, COLOR_YELLOW, "<!> {FFFFFF}Seu cigarro terminou.");

		ClearAnimations(playerid);

		SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);

		cigarettePlayer[playerid][E_SMOKING_CIGARETTE] = false;
	}
}
/// <summary>
/// Timer responsável por apagar após a última tragada. Este
/// é chamado quando um jogador específico dá a última tragada
/// do cigarro. 
/// Intervalo: 2700ms
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Não retorna valores.</returns>
call:CallLastCigarettePuff(playerid)
{
	SendClientMessage(playerid, COLOR_YELLOW, "<!> {FFFFFF}Seu cigarro terminou.");

	ClearAnimations(playerid);

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);

	KillTimer(cigarettePlayer[playerid][E_TIMER_DURATION]);

	cigarettePlayer[playerid][E_SMOKING_CIGARETTE] = false;
}
/*
 *****************************************************************************
*/
/*
 |FUNCTIONS|
*/
/// <summary>
/// Realiza conexão com o servidor MySQL.
/// </summary>
/// <returns>Não retorna valores.</returns>
MySQL_Connect()
{
	mySQL = mysql_connect(mysql_host, mysql_user, mysql_password, mysql_database);

	if(mySQL == MYSQL_INVALID_HANDLE || mysql_errno(mySQL) != 0)
	{
		print("MySQL: Falha ao conectar.");
		SendRconCommand("exit");
		return;
	}
	else
	{
		print("MySQL: Conexão bem sucedida.");
	}
}
/// <summary>
/// Encerra conexão com o servidor MySQL.
/// </summary>
/// <returns>Não retorna valores.</returns>
MySQL_Disconnect()
{
	mysql_close(mySQL);
}
/// <summary>
/// Cria a tabela 'bafore13' se não existir, e valida se a mesma
/// é existente.
/// </summary>
/// <returns>Não retorna valores.</returns>
MySQL_CheckTable()
{
	//mysql_query(mySQL, "CREATE TABLE IF NOT EXISTS `bafore13`(`user` VARCHAR(24) NOT NULL, `cigarette0` BOOLEAN NOT NULL, `cigarette1` BOOLEAN NOT NULL, `cigarette2` BOOLEAN NOT NULL, `cigarette3` BOOLEAN NOT NULL, `cigarette4` BOOLEAN NOT NULL)", false);
	mysql_tquery(mySQL, "SELECT * FROM `bafore13`", "MySQL_OnTableChecked", "s", "bafore13");
}
//----------------------
/// <summary>
/// Cria todas TextDraws Globais da caixa de cigarros Bafore13.
/// </summary>
/// <returns>Não retorna valores.</returns>
CreateGlobalTDBafore13()
{
	textBafore13[E_BOX][0] = TextDrawCreate(531.353149, 274.583374, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_BOX][0], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][0], 93.000000, 153.000000);
	TextDrawAlignment(textBafore13[E_BOX][0], 1);
	TextDrawColor(textBafore13[E_BOX][0], -589505281);
	TextDrawSetShadow(textBafore13[E_BOX][0], 0);
	TextDrawSetOutline(textBafore13[E_BOX][0], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][0], 255);
	TextDrawFont(textBafore13[E_BOX][0], 4);
	TextDrawSetProportional(textBafore13[E_BOX][0], 0);
	TextDrawSetShadow(textBafore13[E_BOX][0], 0);

	textBafore13[E_BOX][1] = TextDrawCreate(550.646911, 323.583435, "LD_OTB:hrs4");
	TextDrawLetterSize(textBafore13[E_BOX][1], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][1], 53.000000, 50.000000);
	TextDrawAlignment(textBafore13[E_BOX][1], 1);
	TextDrawColor(textBafore13[E_BOX][1], -1);
	TextDrawSetShadow(textBafore13[E_BOX][1], 0);
	TextDrawSetOutline(textBafore13[E_BOX][1], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][1], 255);
	TextDrawFont(textBafore13[E_BOX][1], 4);
	TextDrawSetProportional(textBafore13[E_BOX][1], 0);
	TextDrawSetShadow(textBafore13[E_BOX][1], 0);

	textBafore13[E_BOX][2] = TextDrawCreate(531.353088, 274.582977, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_BOX][2], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][2], 93.000000, 43.910015);
	TextDrawAlignment(textBafore13[E_BOX][2], 1);
	TextDrawColor(textBafore13[E_BOX][2], 1835888127);
	TextDrawSetShadow(textBafore13[E_BOX][2], 0);
	TextDrawSetOutline(textBafore13[E_BOX][2], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][2], 255);
	TextDrawFont(textBafore13[E_BOX][2], 4);
	TextDrawSetProportional(textBafore13[E_BOX][2], 0);
	TextDrawSetShadow(textBafore13[E_BOX][2], 0);

	//De baixo da tampa:
	textBafore13[E_BOX][3] = TextDrawCreate(531.353149, 293.833343, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_BOX][3], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][3], 11.000000, 43.000000);
	TextDrawAlignment(textBafore13[E_BOX][3], 1);
	TextDrawColor(textBafore13[E_BOX][3], -589505281);
	TextDrawSetShadow(textBafore13[E_BOX][3], 0);
	TextDrawSetOutline(textBafore13[E_BOX][3], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][3], 255);
	TextDrawFont(textBafore13[E_BOX][3], 4);
	TextDrawSetProportional(textBafore13[E_BOX][3], 0);
	TextDrawSetShadow(textBafore13[E_BOX][3], 0);

	textBafore13[E_BOX][4] = TextDrawCreate(529.941223, 282.266723, "LD_BEAT:chit");
	TextDrawLetterSize(textBafore13[E_BOX][4], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][4], 15.000000, 23.000000);
	TextDrawAlignment(textBafore13[E_BOX][4], 1);
	TextDrawColor(textBafore13[E_BOX][4], -589505281);
	TextDrawSetShadow(textBafore13[E_BOX][4], 0);
	TextDrawSetOutline(textBafore13[E_BOX][4], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][4], 255);
	TextDrawFont(textBafore13[E_BOX][4], 4);
	TextDrawSetProportional(textBafore13[E_BOX][4], 0);
	TextDrawSetShadow(textBafore13[E_BOX][4], 0);

	textBafore13[E_BOX][5] = TextDrawCreate(531.353149, 286.249938, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_BOX][5], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][5], 5.000000, 44.000000);
	TextDrawAlignment(textBafore13[E_BOX][5], 1);
	TextDrawColor(textBafore13[E_BOX][5], -589505281);
	TextDrawSetShadow(textBafore13[E_BOX][5], 0);
	TextDrawSetOutline(textBafore13[E_BOX][5], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][5], 255);
	TextDrawFont(textBafore13[E_BOX][5], 4);
	TextDrawSetProportional(textBafore13[E_BOX][5], 0);
	TextDrawSetShadow(textBafore13[E_BOX][5], 0);

	textBafore13[E_BOX][6] = TextDrawCreate(613.235046, 293.833343, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_BOX][6], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][6], 11.000000, 43.000000);
	TextDrawAlignment(textBafore13[E_BOX][6], 1);
	TextDrawColor(textBafore13[E_BOX][6], -589505281);
	TextDrawSetShadow(textBafore13[E_BOX][6], 0);
	TextDrawSetOutline(textBafore13[E_BOX][6], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][6], 255);
	TextDrawFont(textBafore13[E_BOX][6], 4);
	TextDrawSetProportional(textBafore13[E_BOX][6], 0);
	TextDrawSetShadow(textBafore13[E_BOX][6], 0);

	textBafore13[E_BOX][7] = TextDrawCreate(610.882080, 282.266723, "LD_BEAT:chit");
	TextDrawLetterSize(textBafore13[E_BOX][7], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][7], 15.000000, 23.000000);
	TextDrawAlignment(textBafore13[E_BOX][7], 1);
	TextDrawColor(textBafore13[E_BOX][7], -589505281);
	TextDrawSetShadow(textBafore13[E_BOX][7], 0);
	TextDrawSetOutline(textBafore13[E_BOX][7], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][7], 255);
	TextDrawFont(textBafore13[E_BOX][7], 4);
	TextDrawSetProportional(textBafore13[E_BOX][7], 0);
	TextDrawSetShadow(textBafore13[E_BOX][7], 0);

	textBafore13[E_BOX][8] = TextDrawCreate(619.352539, 286.249938, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_BOX][8], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][8], 5.000000, 44.000000);
	TextDrawAlignment(textBafore13[E_BOX][8], 1);
	TextDrawColor(textBafore13[E_BOX][8], -589505281);
	TextDrawSetShadow(textBafore13[E_BOX][8], 0);
	TextDrawSetOutline(textBafore13[E_BOX][8], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][8], 255);
	TextDrawFont(textBafore13[E_BOX][8], 4);
	TextDrawSetProportional(textBafore13[E_BOX][8], 0);
	TextDrawSetShadow(textBafore13[E_BOX][8], 0);
	//-----------------------------------------------------------------------------------
	//Tampa:
	textBafore13[E_LID_BOX][0] = TextDrawCreate(531.353149, 274.583374, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_LID_BOX][0], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_LID_BOX][0], 93.000000, 43.000000);
	TextDrawAlignment(textBafore13[E_LID_BOX][0], 1);
	TextDrawColor(textBafore13[E_LID_BOX][0], -589505281);
	TextDrawSetShadow(textBafore13[E_LID_BOX][0], 0);
	TextDrawSetOutline(textBafore13[E_LID_BOX][0], 0);
	TextDrawBackgroundColor(textBafore13[E_LID_BOX][0], 255);
	TextDrawFont(textBafore13[E_LID_BOX][0], 4);
	TextDrawSetProportional(textBafore13[E_LID_BOX][0], 0);
	TextDrawSetShadow(textBafore13[E_LID_BOX][0], 0);

	textBafore13[E_LID_BOX][1] = TextDrawCreate(537.000061, 280.416778, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_LID_BOX][1], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_LID_BOX][1], 82.000000, 7.000000);
	TextDrawAlignment(textBafore13[E_LID_BOX][1], 1);
	TextDrawColor(textBafore13[E_LID_BOX][1], -1523963137);
	TextDrawSetShadow(textBafore13[E_LID_BOX][1], 0);
	TextDrawSetOutline(textBafore13[E_LID_BOX][1], 0);
	TextDrawBackgroundColor(textBafore13[E_LID_BOX][1], 255);
	TextDrawFont(textBafore13[E_LID_BOX][1], 4);
	TextDrawSetProportional(textBafore13[E_LID_BOX][1], 0);
	TextDrawSetShadow(textBafore13[E_LID_BOX][1], 0);

	textBafore13[E_LID_BOX][2] = TextDrawCreate(578.000000, 279.833251, "Edicao especial");
	TextDrawLetterSize(textBafore13[E_LID_BOX][2], 0.200470, 0.771664);
	TextDrawAlignment(textBafore13[E_LID_BOX][2], 2);
	TextDrawColor(textBafore13[E_LID_BOX][2], -1);
	TextDrawSetShadow(textBafore13[E_LID_BOX][2], 0);
	TextDrawSetOutline(textBafore13[E_LID_BOX][2], 0);
	TextDrawBackgroundColor(textBafore13[E_LID_BOX][2], 255);
	TextDrawFont(textBafore13[E_LID_BOX][2], 2);
	TextDrawSetProportional(textBafore13[E_LID_BOX][2], 1);
	TextDrawSetShadow(textBafore13[E_LID_BOX][2], 0);

	textBafore13[E_LID_BOX][3] = TextDrawCreate(577.999572, 293.833404, "Silver Edition");
	TextDrawLetterSize(textBafore13[E_LID_BOX][3], 0.339762, 1.343333);
	TextDrawAlignment(textBafore13[E_LID_BOX][3], 2);
	TextDrawColor(textBafore13[E_LID_BOX][3], -1523963137);
	TextDrawSetShadow(textBafore13[E_LID_BOX][3], 0);
	TextDrawSetOutline(textBafore13[E_LID_BOX][3], 0);
	TextDrawBackgroundColor(textBafore13[E_LID_BOX][3], 255);
	TextDrawFont(textBafore13[E_LID_BOX][3], 3);
	TextDrawSetProportional(textBafore13[E_LID_BOX][3], 1);
	TextDrawSetShadow(textBafore13[E_LID_BOX][3], 0);
	//-----------------------------------------------
	textBafore13[E_BOX][9] = TextDrawCreate(548.353027, 372.000335, "Bafore");
	TextDrawLetterSize(textBafore13[E_BOX][9], 0.597176, 2.520833);
	TextDrawAlignment(textBafore13[E_BOX][9], 1);
	TextDrawColor(textBafore13[E_BOX][9], 255);
	TextDrawSetShadow(textBafore13[E_BOX][9], 0);
	TextDrawSetOutline(textBafore13[E_BOX][9], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][9], 255);
	TextDrawFont(textBafore13[E_BOX][9], 0);
	TextDrawSetProportional(textBafore13[E_BOX][9], 1);
	TextDrawSetShadow(textBafore13[E_BOX][9], 0);

	textBafore13[E_BOX][10] = TextDrawCreate(548.353027, 372.000335, "Bafore");
	TextDrawLetterSize(textBafore13[E_BOX][10], 0.597176, 2.520833);
	TextDrawAlignment(textBafore13[E_BOX][10], 1);
	TextDrawColor(textBafore13[E_BOX][10], 1835888127);
	TextDrawSetShadow(textBafore13[E_BOX][10], 0);
	TextDrawSetOutline(textBafore13[E_BOX][10], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][10], 255);
	TextDrawFont(textBafore13[E_BOX][10], 0);
	TextDrawSetProportional(textBafore13[E_BOX][10], 1);
	TextDrawSetShadow(textBafore13[E_BOX][10], 0);

	textBafore13[E_BOX][11] = TextDrawCreate(593.058654, 371.417053, "13");
	TextDrawLetterSize(textBafore13[E_BOX][11], 0.353882, 2.865000);
	TextDrawAlignment(textBafore13[E_BOX][11], 1);
	TextDrawColor(textBafore13[E_BOX][11], 255);
	TextDrawSetShadow(textBafore13[E_BOX][11], 0);
	TextDrawSetOutline(textBafore13[E_BOX][11], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][11], 255);
	TextDrawFont(textBafore13[E_BOX][11], 2);
	TextDrawSetProportional(textBafore13[E_BOX][11], 1);
	TextDrawSetShadow(textBafore13[E_BOX][11], 0);

	textBafore13[E_BOX][12] = TextDrawCreate(593.058654, 371.417053, "13");
	TextDrawLetterSize(textBafore13[E_BOX][12], 0.353882, 2.865000);
	TextDrawAlignment(textBafore13[E_BOX][12], 1);
	TextDrawColor(textBafore13[E_BOX][12], 1835888127);
	TextDrawSetShadow(textBafore13[E_BOX][12], 0);
	TextDrawSetOutline(textBafore13[E_BOX][12], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][12], 255);
	TextDrawFont(textBafore13[E_BOX][12], 2);
	TextDrawSetProportional(textBafore13[E_BOX][12], 1);
	TextDrawSetShadow(textBafore13[E_BOX][12], 0);

	textBafore13[E_BOX][13] = TextDrawCreate(577.999572, 398.250061, "contem 5 cigarros");
	TextDrawLetterSize(textBafore13[E_BOX][13], 0.162643, 0.846665);
	TextDrawAlignment(textBafore13[E_BOX][13], 2);
	TextDrawColor(textBafore13[E_BOX][13], 1835888127);
	TextDrawSetShadow(textBafore13[E_BOX][13], 0);
	TextDrawSetOutline(textBafore13[E_BOX][13], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][13], 255);
	TextDrawFont(textBafore13[E_BOX][13], 2);
	TextDrawSetProportional(textBafore13[E_BOX][13], 1);
	TextDrawSetShadow(textBafore13[E_BOX][13], 0);

	textBafore13[E_BOX][14] = TextDrawCreate(533.235473, 410.499969, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_BOX][14], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_BOX][14], 89.000000, 15.000000);
	TextDrawAlignment(textBafore13[E_BOX][14], 1);
	TextDrawColor(textBafore13[E_BOX][14], 255);
	TextDrawSetShadow(textBafore13[E_BOX][14], 0);
	TextDrawSetOutline(textBafore13[E_BOX][14], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][14], 255);
	TextDrawFont(textBafore13[E_BOX][14], 4);
	TextDrawSetProportional(textBafore13[E_BOX][14], 0);
	TextDrawSetShadow(textBafore13[E_BOX][14], 0);

	textBafore13[E_BOX][15] = TextDrawCreate(577.999694, 409.916625, "Este produto pode causar~n~cancer_e_problemas_de_saude.");
	TextDrawLetterSize(textBafore13[E_BOX][15], 0.129703, 0.834998);
	TextDrawAlignment(textBafore13[E_BOX][15], 2);
	TextDrawColor(textBafore13[E_BOX][15], -1);
	TextDrawSetShadow(textBafore13[E_BOX][15], 0);
	TextDrawSetOutline(textBafore13[E_BOX][15], 0);
	TextDrawBackgroundColor(textBafore13[E_BOX][15], 255);
	TextDrawFont(textBafore13[E_BOX][15], 2);
	TextDrawSetProportional(textBafore13[E_BOX][15], 1);
	TextDrawSetShadow(textBafore13[E_BOX][15], 0);

	textBafore13[E_LID_BOX_CLICK] = TextDrawCreate(531.353088, 274.582977, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_LID_BOX_CLICK], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_LID_BOX_CLICK], 93.000000, 43.910015);
	TextDrawAlignment(textBafore13[E_LID_BOX_CLICK], 1);
	TextDrawColor(textBafore13[E_LID_BOX_CLICK], -589505536);
	TextDrawSetShadow(textBafore13[E_LID_BOX_CLICK], 0);
	TextDrawSetOutline(textBafore13[E_LID_BOX_CLICK], 0);
	TextDrawBackgroundColor(textBafore13[E_LID_BOX_CLICK], 255);
	TextDrawFont(textBafore13[E_LID_BOX_CLICK], 4);
	TextDrawSetProportional(textBafore13[E_LID_BOX_CLICK], 0);
	TextDrawSetShadow(textBafore13[E_LID_BOX_CLICK], 0);
	TextDrawSetSelectable(textBafore13[E_LID_BOX_CLICK], true);
	/*********************************************************/
	//Cigarette 0
	textBafore13[E_CIGARETTE][0][0] = TextDrawCreate(545.000366, 318.333465, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][0], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][0][0], 10.000000, -39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][0], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][0], -40238593);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][0], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][0], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][0], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][0], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][0], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][0], 0);
	TextDrawSetSelectable(textBafore13[E_CIGARETTE][0][0], true);

	textBafore13[E_CIGARETTE][0][1] = TextDrawCreate(545.000366, 318.333465, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][1], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][0][1], 10.000000, -8.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][1], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][1], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][1], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][1], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][1], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][1], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][1], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][1], 0);

	textBafore13[E_CIGARETTE][0][2] = TextDrawCreate(545.529479, 272.833221, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][2], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][2], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][2], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][2], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][2], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][2], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][2], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][2], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][2], 0);

	textBafore13[E_CIGARETTE][0][3] = TextDrawCreate(550.705871, 276.333282, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][3], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][3], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][3], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][3], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][3], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][3], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][3], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][3], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][3], 0);

	textBafore13[E_CIGARETTE][0][4] = TextDrawCreate(553.529357, 295.000030, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][4], -0.164233, 1.378332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][4], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][4], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][4], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][4], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][4], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][4], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][4], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][4], 0);

	textBafore13[E_CIGARETTE][0][5] = TextDrawCreate(548.823547, 282.166625, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][5], -0.178350, 1.366665);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][5], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][5], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][5], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][5], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][5], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][5], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][5], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][5], 0);

	textBafore13[E_CIGARETTE][0][6] = TextDrawCreate(550.705932, 306.083374, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][6], 0.166115, -1.515002);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][6], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][6], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][6], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][6], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][6], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][6], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][6], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][6], 0);

	textBafore13[E_CIGARETTE][0][7] = TextDrawCreate(547.882446, 290.916778, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][7], 0.169411, 1.349166);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][7], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][7], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][7], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][7], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][7], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][7], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][7], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][7], 0);

	textBafore13[E_CIGARETTE][0][8] = TextDrawCreate(550.235351, 276.333312, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][8], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][8], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][8], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][8], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][8], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][8], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][8], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][8], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][8], 0);

	textBafore13[E_CIGARETTE][0][9] = TextDrawCreate(548.353027, 302.000091, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][9], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][9], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][9], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][9], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][9], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][9], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][9], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][9], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][9], 0);

	textBafore13[E_CIGARETTE][0][10] = TextDrawCreate(552.588256, 286.250122, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][10], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][10], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][10], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][10], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][10], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][10], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][10], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][10], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][10], 0);

	textBafore13[E_CIGARETTE][0][11] = TextDrawCreate(546.941284, 282.166748, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][11], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][11], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][11], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][11], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][11], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][11], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][11], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][11], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][11], 0);

	textBafore13[E_CIGARETTE][0][12] = TextDrawCreate(546.941284, 292.083557, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][0][12], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][0][12], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][0][12], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][12], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][0][12], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][0][12], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][0][12], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][0][12], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][0][12], 0);

	//Cigarette 1
	textBafore13[E_CIGARETTE][1][0] = TextDrawCreate(559.117736, 318.333465, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][0], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][1][0], 10.000000, -39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][0], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][0], -40238593);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][0], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][0], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][0], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][0], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][0], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][0], 0);

	textBafore13[E_CIGARETTE][1][1] = TextDrawCreate(559.117736, 318.333465, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][1], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][1][1], 10.000000, -8.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][1], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][1], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][1], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][1], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][1], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][1], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][1], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][1], 0);

	textBafore13[E_CIGARETTE][1][2] = TextDrawCreate(559.646850, 272.833221, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][2], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][2], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][2], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][2], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][2], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][2], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][2], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][2], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][2], 0);

	textBafore13[E_CIGARETTE][1][3] = TextDrawCreate(564.823242, 276.333282, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][3], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][3], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][3], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][3], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][3], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][3], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][3], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][3], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][3], 0);

	textBafore13[E_CIGARETTE][1][4] = TextDrawCreate(567.646728, 295.000030, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][4], -0.164233, 1.378332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][4], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][4], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][4], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][4], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][4], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][4], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][4], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][4], 0);

	textBafore13[E_CIGARETTE][1][5] = TextDrawCreate(562.940917, 282.166625, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][5], -0.178350, 1.366665);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][5], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][5], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][5], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][5], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][5], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][5], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][5], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][5], 0);

	textBafore13[E_CIGARETTE][1][6] = TextDrawCreate(564.823303, 306.083374, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][6], 0.166115, -1.515002);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][6], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][6], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][6], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][6], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][6], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][6], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][6], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][6], 0);

	textBafore13[E_CIGARETTE][1][7] = TextDrawCreate(561.999816, 290.916778, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][7], 0.169411, 1.349166);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][7], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][7], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][7], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][7], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][7], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][7], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][7], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][7], 0);

	textBafore13[E_CIGARETTE][1][8] = TextDrawCreate(564.352722, 276.333312, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][8], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][8], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][8], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][8], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][8], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][8], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][8], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][8], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][8], 0);

	textBafore13[E_CIGARETTE][1][9] = TextDrawCreate(562.470397, 302.000091, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][9], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][9], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][9], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][9], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][9], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][9], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][9], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][9], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][9], 0);

	textBafore13[E_CIGARETTE][1][10] = TextDrawCreate(566.705627, 286.250122, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][10], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][10], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][10], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][10], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][10], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][10], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][10], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][10], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][10], 0);

	textBafore13[E_CIGARETTE][1][11] = TextDrawCreate(561.058654, 282.166748, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][11], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][11], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][11], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][11], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][11], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][11], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][11], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][11], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][11], 0);

	textBafore13[E_CIGARETTE][1][12] = TextDrawCreate(561.058654, 292.083557, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][1][12], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][1][12], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][1][12], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][12], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][1][12], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][1][12], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][1][12], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][1][12], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][1][12], 0);

	//Cigarette 2
	textBafore13[E_CIGARETTE][2][0] = TextDrawCreate(573.235168, 317.933441, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][0], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][2][0], 10.000000, -39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][0], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][0], -40238593);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][0], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][0], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][0], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][0], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][0], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][0], 0);

	textBafore13[E_CIGARETTE][2][1] = TextDrawCreate(573.235168, 317.933441, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][1], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][2][1], 10.000000, -8.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][1], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][1], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][1], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][1], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][1], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][1], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][1], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][1], 0);

	textBafore13[E_CIGARETTE][2][2] = TextDrawCreate(573.764282, 272.433197, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][2], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][2], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][2], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][2], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][2], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][2], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][2], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][2], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][2], 0);

	textBafore13[E_CIGARETTE][2][3] = TextDrawCreate(578.940673, 275.933258, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][3], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][3], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][3], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][3], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][3], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][3], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][3], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][3], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][3], 0);

	textBafore13[E_CIGARETTE][2][4] = TextDrawCreate(581.764160, 294.600006, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][4], -0.164233, 1.378332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][4], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][4], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][4], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][4], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][4], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][4], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][4], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][4], 0);

	textBafore13[E_CIGARETTE][2][5] = TextDrawCreate(577.058349, 281.766601, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][5], -0.178350, 1.366665);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][5], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][5], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][5], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][5], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][5], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][5], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][5], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][5], 0);

	textBafore13[E_CIGARETTE][2][6] = TextDrawCreate(578.940734, 305.683349, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][6], 0.166115, -1.515002);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][6], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][6], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][6], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][6], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][6], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][6], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][6], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][6], 0);

	textBafore13[E_CIGARETTE][2][7] = TextDrawCreate(576.117248, 290.516754, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][7], 0.169411, 1.349166);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][7], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][7], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][7], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][7], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][7], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][7], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][7], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][7], 0);

	textBafore13[E_CIGARETTE][2][8] = TextDrawCreate(578.470153, 275.933288, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][8], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][8], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][8], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][8], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][8], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][8], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][8], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][8], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][8], 0);

	textBafore13[E_CIGARETTE][2][9] = TextDrawCreate(576.587829, 301.600067, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][9], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][9], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][9], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][9], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][9], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][9], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][9], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][9], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][9], 0);

	textBafore13[E_CIGARETTE][2][10] = TextDrawCreate(580.823059, 285.850097, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][10], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][10], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][10], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][10], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][10], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][10], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][10], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][10], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][10], 0);

	textBafore13[E_CIGARETTE][2][11] = TextDrawCreate(575.176086, 281.766723, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][11], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][11], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][11], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][11], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][11], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][11], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][11], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][11], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][11], 0);

	textBafore13[E_CIGARETTE][2][12] = TextDrawCreate(575.176086, 291.683532, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][2][12], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][2][12], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][2][12], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][12], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][2][12], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][2][12], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][2][12], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][2][12], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][2][12], 0);

	//Cigarette 3
	textBafore13[E_CIGARETTE][3][0] = TextDrawCreate(587.352600, 317.933441, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][0], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][3][0], 10.000000, -39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][0], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][0], -40238593);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][0], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][0], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][0], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][0], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][0], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][0], 0);

	textBafore13[E_CIGARETTE][3][1] = TextDrawCreate(587.352600, 317.933441, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][1], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][3][1], 10.000000, -8.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][1], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][1], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][1], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][1], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][1], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][1], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][1], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][1], 0);

	textBafore13[E_CIGARETTE][3][2] = TextDrawCreate(587.881713, 272.433197, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][2], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][2], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][2], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][2], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][2], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][2], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][2], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][2], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][2], 0);

	textBafore13[E_CIGARETTE][3][3] = TextDrawCreate(593.058105, 275.933258, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][3], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][3], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][3], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][3], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][3], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][3], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][3], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][3], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][3], 0);

	textBafore13[E_CIGARETTE][3][4] = TextDrawCreate(595.881591, 294.600006, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][4], -0.164233, 1.378332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][4], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][4], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][4], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][4], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][4], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][4], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][4], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][4], 0);

	textBafore13[E_CIGARETTE][3][5] = TextDrawCreate(591.175781, 281.766601, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][5], -0.178350, 1.366665);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][5], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][5], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][5], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][5], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][5], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][5], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][5], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][5], 0);

	textBafore13[E_CIGARETTE][3][6] = TextDrawCreate(593.058166, 305.683349, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][6], 0.166115, -1.515002);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][6], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][6], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][6], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][6], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][6], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][6], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][6], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][6], 0);

	textBafore13[E_CIGARETTE][3][7] = TextDrawCreate(590.234680, 290.516754, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][7], 0.169411, 1.349166);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][7], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][7], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][7], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][7], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][7], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][7], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][7], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][7], 0);

	textBafore13[E_CIGARETTE][3][8] = TextDrawCreate(592.587585, 275.933288, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][8], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][8], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][8], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][8], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][8], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][8], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][8], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][8], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][8], 0);

	textBafore13[E_CIGARETTE][3][9] = TextDrawCreate(590.705261, 301.600067, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][9], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][9], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][9], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][9], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][9], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][9], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][9], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][9], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][9], 0);

	textBafore13[E_CIGARETTE][3][10] = TextDrawCreate(594.940490, 285.850097, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][10], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][10], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][10], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][10], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][10], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][10], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][10], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][10], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][10], 0);

	textBafore13[E_CIGARETTE][3][11] = TextDrawCreate(589.293518, 281.766723, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][11], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][11], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][11], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][11], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][11], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][11], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][11], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][11], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][11], 0);

	textBafore13[E_CIGARETTE][3][12] = TextDrawCreate(589.293518, 291.683532, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][3][12], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][3][12], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][3][12], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][12], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][3][12], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][3][12], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][3][12], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][3][12], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][3][12], 0);

	//Cigarette 4
	textBafore13[E_CIGARETTE][4][0] = TextDrawCreate(600.998779, 317.933227, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][0], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][4][0], 10.000000, -39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][0], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][0], -40238593);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][0], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][0], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][0], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][0], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][0], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][0], 0);

	textBafore13[E_CIGARETTE][4][1] = TextDrawCreate(600.998779, 317.933227, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][1], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE][4][1], 10.000000, -8.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][1], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][1], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][1], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][1], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][1], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][1], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][1], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][1], 0);

	textBafore13[E_CIGARETTE][4][2] = TextDrawCreate(601.527893, 272.432983, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][2], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][2], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][2], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][2], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][2], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][2], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][2], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][2], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][2], 0);

	textBafore13[E_CIGARETTE][4][3] = TextDrawCreate(606.704223, 275.933044, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][3], 0.229644, 1.343332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][3], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][3], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][3], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][3], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][3], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][3], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][3], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][3], 0);

	textBafore13[E_CIGARETTE][4][4] = TextDrawCreate(609.527709, 294.599792, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][4], -0.164233, 1.378332);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][4], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][4], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][4], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][4], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][4], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][4], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][4], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][4], 0);

	textBafore13[E_CIGARETTE][4][5] = TextDrawCreate(604.821899, 281.766387, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][5], -0.178350, 1.366665);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][5], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][5], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][5], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][5], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][5], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][5], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][5], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][5], 0);

	textBafore13[E_CIGARETTE][4][6] = TextDrawCreate(606.704284, 305.683135, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][6], 0.166115, -1.515002);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][6], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][6], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][6], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][6], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][6], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][6], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][6], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][6], 0);

	textBafore13[E_CIGARETTE][4][7] = TextDrawCreate(603.880859, 290.516540, ",");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][7], 0.169411, 1.349166);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][7], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][7], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][7], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][7], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][7], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][7], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][7], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][7], 0);

	textBafore13[E_CIGARETTE][4][8] = TextDrawCreate(606.233703, 275.933074, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][8], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][8], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][8], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][8], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][8], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][8], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][8], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][8], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][8], 0);

	textBafore13[E_CIGARETTE][4][9] = TextDrawCreate(604.351379, 301.599853, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][9], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][9], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][9], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][9], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][9], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][9], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][9], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][9], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][9], 0);

	textBafore13[E_CIGARETTE][4][10] = TextDrawCreate(608.586608, 285.849884, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][10], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][10], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][10], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][10], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][10], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][10], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][10], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][10], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][10], 0);

	textBafore13[E_CIGARETTE][4][11] = TextDrawCreate(602.939697, 281.766510, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][11], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][11], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][11], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][11], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][11], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][11], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][11], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][11], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][11], 0);

	textBafore13[E_CIGARETTE][4][12] = TextDrawCreate(602.939697, 291.683319, ".");
	TextDrawLetterSize(textBafore13[E_CIGARETTE][4][12], 0.138352, 0.672499);
	TextDrawAlignment(textBafore13[E_CIGARETTE][4][12], 1);
	TextDrawColor(textBafore13[E_CIGARETTE][4][12], -1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][12], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE][4][12], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE][4][12], 255);
	TextDrawFont(textBafore13[E_CIGARETTE][4][12], 1);
	TextDrawSetProportional(textBafore13[E_CIGARETTE][4][12], 1);
	TextDrawSetShadow(textBafore13[E_CIGARETTE][4][12], 0);
	//-------------------------------------------------------------------------------------------
	textBafore13[E_CIGARETTE_CLICK][0] = TextDrawCreate(545.000366, 279.250244, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE_CLICK][0], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE_CLICK][0], 10.000000, 39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE_CLICK][0], 1);
	TextDrawColor(textBafore13[E_CIGARETTE_CLICK][0], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][0], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE_CLICK][0], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE_CLICK][0], 255);
	TextDrawFont(textBafore13[E_CIGARETTE_CLICK][0], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE_CLICK][0], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][0], 0);
	TextDrawSetSelectable(textBafore13[E_CIGARETTE_CLICK][0], true);

	textBafore13[E_CIGARETTE_CLICK][1] = TextDrawCreate(559.117797, 279.250244, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE_CLICK][1], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE_CLICK][1], 10.000000, 39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE_CLICK][1], 1);
	TextDrawColor(textBafore13[E_CIGARETTE_CLICK][1], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][1], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE_CLICK][1], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE_CLICK][1], 255);
	TextDrawFont(textBafore13[E_CIGARETTE_CLICK][1], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE_CLICK][1], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][1], 0);
	TextDrawSetSelectable(textBafore13[E_CIGARETTE_CLICK][1], true);

	textBafore13[E_CIGARETTE_CLICK][2] = TextDrawCreate(573.235290, 279.250244, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE_CLICK][2], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE_CLICK][2], 10.000000, 39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE_CLICK][2], 1);
	TextDrawColor(textBafore13[E_CIGARETTE_CLICK][2], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][2], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE_CLICK][2], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE_CLICK][2], 255);
	TextDrawFont(textBafore13[E_CIGARETTE_CLICK][2], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE_CLICK][2], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][2], 0);
	TextDrawSetSelectable(textBafore13[E_CIGARETTE_CLICK][2], true);

	textBafore13[E_CIGARETTE_CLICK][3] = TextDrawCreate(587.352722, 279.250244, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE_CLICK][3], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE_CLICK][3], 10.000000, 39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE_CLICK][3], 1);
	TextDrawColor(textBafore13[E_CIGARETTE_CLICK][3], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][3], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE_CLICK][3], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE_CLICK][3], 255);
	TextDrawFont(textBafore13[E_CIGARETTE_CLICK][3], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE_CLICK][3], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][3], 0);
	TextDrawSetSelectable(textBafore13[E_CIGARETTE_CLICK][3], true);

	textBafore13[E_CIGARETTE_CLICK][4] = TextDrawCreate(600.999572, 279.250244, "LD_SPAC:white");
	TextDrawLetterSize(textBafore13[E_CIGARETTE_CLICK][4], 0.000000, 0.000000);
	TextDrawTextSize(textBafore13[E_CIGARETTE_CLICK][4], 10.000000, 39.000000);
	TextDrawAlignment(textBafore13[E_CIGARETTE_CLICK][4], 1);
	TextDrawColor(textBafore13[E_CIGARETTE_CLICK][4], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][4], 0);
	TextDrawSetOutline(textBafore13[E_CIGARETTE_CLICK][4], 0);
	TextDrawBackgroundColor(textBafore13[E_CIGARETTE_CLICK][4], 255);
	TextDrawFont(textBafore13[E_CIGARETTE_CLICK][4], 4);
	TextDrawSetProportional(textBafore13[E_CIGARETTE_CLICK][4], 0);
	TextDrawSetShadow(textBafore13[E_CIGARETTE_CLICK][4], 0);
	TextDrawSetSelectable(textBafore13[E_CIGARETTE_CLICK][4], true);
}
//-----------------------------
/// <summary>
/// Reseta a variável de controle dos cigarros de um jogador
/// específico.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Não retorna valores.</returns>
ResetPlayerCigarretes(playerid)
{
	for(new i; i < 5; i++)
	{
	    cigarettePlayer[playerid][E_HAVE_CIGARETTE][i] = false;
	}
	
	cigarettePlayer[playerid][E_PACKAGE_OPENED] = false;
	cigarettePlayer[playerid][E_SMOKING_CIGARETTE] = false;
}
/// <summary>
/// Carrega os cigarros de um jogador específico do banco de dados.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Não retorna valores.</returns>
LoadPlayerCigarettes(playerid)
{
	mysql_format(mySQL, myQuery, sizeof(myQuery), "SELECT * FROM `bafore13` WHERE `user` = '%s'", GetNameOfPlayer(playerid));
	mysql_tquery(mySQL, myQuery, "MySQL_OnPlayerCigarettesLoaded", "d", playerid);
}
/// <summary>
/// Salva os cigarros de um jogador específico no banco de dados.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Não retorna valores.</returns>
SavePlayerCigarettes(playerid)
{
	mysql_format(mySQL, myQuery, sizeof(myQuery), "UPDATE `bafore13` SET cigarette0 = '%b', cigarette1 = '%b', cigarette2 = '%b', cigarette3 = '%b', cigarette4 = '%b' WHERE `user` = '%s'", 
		cigarettePlayer[playerid][E_HAVE_CIGARETTE][0],
		cigarettePlayer[playerid][E_HAVE_CIGARETTE][1],
		cigarettePlayer[playerid][E_HAVE_CIGARETTE][2],
		cigarettePlayer[playerid][E_HAVE_CIGARETTE][3],
		cigarettePlayer[playerid][E_HAVE_CIGARETTE][4],
		GetNameOfPlayer(playerid));

	mysql_tquery(mySQL, myQuery, "MySQL_OnPlayerCigarettesSaved", "s", GetNameOfPlayer(playerid));
}
//-----------------------------------
/// <summary>
/// Da uma quantidade específica de cigarros a um jogador específico.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <param name="amount">Quantidade de cigarros.</param>
/// <returns>True se bem sucedido, False se já atingiu o máximo de cigarros possíveis.</returns>
GivePlayerCigarette(playerid, amount)
{
	if(!(0 < amount <= 5)) return false;

	new count, i;

	for(i = 0; i < 5; i++)
	{
		if(!cigarettePlayer[playerid][E_HAVE_CIGARETTE][i])
		{
		    cigarettePlayer[playerid][E_HAVE_CIGARETTE][i] = true;

		    count++;

		    if(count == amount) break;
		}
	}

	return bool:count;
}
//----------------------------------
/// <summary>
/// Mostra a caixa de cigarros a um jogador específico.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>True se bem sucedido, False se já foi mostrada.</returns>
ShowPlayerCigarettePackage(playerid)
{
	if(cigarettePlayer[playerid][E_PACKAGE_OPENED]) return false;

	new i;

	for(i = 0; i < 16; i++)
	{
		if(3 <= i <= 8) continue;

		TextDrawShowForPlayer(playerid, textBafore13[E_BOX][i]);
	}

	for(i = 0; i < 4; i++) TextDrawShowForPlayer(playerid, textBafore13[E_LID_BOX][i]);

	TextDrawShowForPlayer(playerid, textBafore13[E_LID_BOX_CLICK]);

	cigarettePlayer[playerid][E_PACKAGE_OPENED] = true;

	SelectTextDraw(playerid, 0x00000040);

	return true;
}
/// <summary>
/// Esconde a caixa de cigarros de um jogador específico.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>True se bem sucedido, False se já foi escondida.</returns>
HidePlayerCigarettePackage(playerid)
{
	if(!cigarettePlayer[playerid][E_PACKAGE_OPENED]) return false;

	new i, j;

	CancelSelectTextDraw(playerid);

	for(i = 0; i < 16; i++)
	{
		TextDrawHideForPlayer(playerid, textBafore13[E_BOX][i]);

		if(i < 4) TextDrawHideForPlayer(playerid, textBafore13[E_LID_BOX][i]);
	}

	TextDrawHideForPlayer(playerid, textBafore13[E_LID_BOX_CLICK]);

	for(i = 0; i < 5; i++)
	{
		for(j = 0; j < 13; j++) TextDrawHideForPlayer(playerid, textBafore13[E_CIGARETTE][i][j]);

		TextDrawHideForPlayer(playerid, textBafore13[E_CIGARETTE_CLICK][i]);
	}

	cigarettePlayer[playerid][E_PACKAGE_OPENED] = false;

	return true;
}
//-----------------------------------
/// <summary>
/// Acende um cigarro específico de um jogador específico.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <param name="cigaretteid">ID do cigarro.</param>
/// <returns>True se bem sucedido, False se não possuir o cigarro.</returns>
SmokeCigarette(playerid, cigaretteid)
{
	if(!cigarettePlayer[playerid][E_HAVE_CIGARETTE][cigaretteid]) return false;

	cigarettePlayer[playerid][E_HAVE_CIGARETTE][cigaretteid] = false;

    cigarettePlayer[playerid][E_SMOKING_CIGARETTE] = true;

    cigarettePlayer[playerid][E_COUNT_PUFF_CIGARETTE] = CIGARETTE_PUFF;

    cigarettePlayer[playerid][E_TIMER_DURATION] = SetTimerEx("BurningCigarette", 60000, false, "i", playerid);

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_SMOKE_CIGGY);
	
	return true;
}
//--------------------------
/// <summary>
/// Mostra a um jogador específico os cigarros que o mesmo possuir.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>True se bem sucedido, False se a carteira de cigarros não foi mostrada.</returns>
UpdateTDCigarettes(playerid)
{
	if(!cigarettePlayer[playerid][E_PACKAGE_OPENED]) return false;

	for(new i, j; i < 5; i++)
	{
		if(cigarettePlayer[playerid][E_HAVE_CIGARETTE][i])
		{
			for(j = 0; j < 13; j++) TextDrawShowForPlayer(playerid, textBafore13[E_CIGARETTE][i][j]);

			TextDrawShowForPlayer(playerid, textBafore13[E_CIGARETTE_CLICK][i]);
		}
	}

	return true;
}
/// <summary>
/// Abre a caixa de cigarros de um jogador específico.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Não retorna valores.</returns>
OpenCigaretteBox(playerid)
{
	new i;

	for(i = 0; i < 4; i++) TextDrawHideForPlayer(playerid, textBafore13[E_LID_BOX][i]);

	TextDrawHideForPlayer(playerid, textBafore13[E_LID_BOX_CLICK]);

	for(i = 3; i <= 8; i++)
	{
		TextDrawShowForPlayer(playerid, textBafore13[E_BOX][i]);
	}
	
	UpdateTDCigarettes(playerid);

	SelectTextDraw(playerid, 0x00000040);
}
/*
 *****************************************************************************
*/
/*
 |COMPLEMENTS|
*/
/// <author>
/// Bruno13
/// </author>
/// <summary>
/// Obtem e retorna o nome de um jogador específico.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Nome do jogador.</returns>
GetNameOfPlayer(playerid)
{
	new name[MAX_PLAYER_NAME];
	return GetPlayerName(playerid, name, sizeof(name)), name;
}
/*
 *****************************************************************************
*/
/*
 |COMMANDS|
*/
/// <summary>
/// Comando para pegar/guardar a caixa de cigarros.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Não retorna valores específicos.</returns>
CMD:fumar(playerid)
{
	if(cigarettePlayer[playerid][E_SMOKING_CIGARETTE]) return SendClientMessage(playerid, COLOR_RED, "<!> {FFFFFF}Você já acendeu um cigarro.");
	
	if(CIGARETTE_ACCESS_IF_HAVE)
	{
		for(new i; i < 5; i++)
		{
			if(cigarettePlayer[playerid][E_HAVE_CIGARETTE][i]) break;

			if(i == 4) return SendClientMessage(playerid, COLOR_RED, "<!> {FFFFFF}Você não possui cigarros.");
		}
	}

	if(cigarettePlayer[playerid][E_PACKAGE_OPENED])
		HidePlayerCigarettePackage(playerid);
	else
		ShowPlayerCigarettePackage(playerid);

	return 1;
}
/// <summary>
/// Comando para dar uma quantia de cigarros específica a um
/// jogador específico.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <param name="params">Parâmetros a serem utilizados: <id do jogador> <quantia>.</param>
/// <returns>Não retorna valores específicos.</returns>
CMD:darcigarro(playerid, params[])
{
    new id, amount;
    
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, COLOR_RED, "<!> {FFFFFF}Você não tem autorização para utilizar esse comando!");
	
	if(sscanf(params,"ud", id, amount)) return SendClientMessage(playerid, -1, "Use: /darcigarro <id> <quantia>");
	
	if(!(0 < amount <= 5)) return SendClientMessage(playerid, COLOR_RED, "<!> {FFFFFF}O número de cigarros deve estar em 1 e 5!");
	
	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, COLOR_RED, "<!> {FFFFFF}Este jogador não está conectado!");
	
	SendClientMessageEx(playerid, COLOR_GREEN, "<!> {FFFFFF}Você deu %d cigarros para %s.", amount, GetNameOfPlayer(id));
	if(playerid != id) SendClientMessageEx(id, COLOR_GREEN, "<!> {FFFFFF}Você recebeu %d cigarros de %s.", amount, GetNameOfPlayer(playerid));
	
	GivePlayerCigarette(id, amount);

	UpdateTDCigarettes(id);

	return 1;
}
/// <summary>
/// Comando para obter uma caixa de cigarros completa.
/// Somente para jogadores logados na RCON.
/// </summary>
/// <param name="playerid">ID do jogador.</param>
/// <returns>Não retorna valores específicos.</returns>
CMD:getcigar(playerid)
{
	if(IsPlayerAdmin(playerid)) GivePlayerCigarette(playerid, CIGARETTE_PACKAGE_FULL);

	return 1;

}