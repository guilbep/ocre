/**
 * OCRe - The ultimate OCR - HUGE Software
 * OCRe is a project developed by 2nd year EPITA students
 * - website: http://huge.ocre.free.fr/
 * - svn repository: http://code.google.com/p/ocre
 *
 * About this folder: /extraction
 *   OCRec is the character extraction part of OCRe.
 * About this file: /extraction/launch.c
 *   This file contains functions which start the extraction
 *   process.
 */

#include <stdlib.h>
#include "structures.h"
#include "init.h"
#include "process.h"
#include "event.h"
#include "SDL/SDL.h"
#include "infos.h"
#include "tools.h"
#include "wrappers.h"

/**
 * This function starts the extraction process with
 * the display option.
 * @param infos Informations about the launch process.
 */
void launchProgramWithDisplay(t_launch_infos *infos)
{
  SDL_Surface *screen;

  screen = NULL;
  if (infos->inFile != NULL && infos->outFile != NULL)
    {
      if (is_bmp(infos->inFile))
	{
	  InitSDL(screen,1);
	  /* Process */
	  waitLoop();
	  SDL_Quit();
	}
      else
	{
	  help("extract");
	  wfree(infos);
	  exit(EXIT_SUCCESS);
	}
    }
}

/**
 * This function starts the extraction process without
 * the display option.
 * @param infos Informations about the launch process.
 */
void launchProgramWithoutDisplay(t_launch_infos *infos)
{
  SDL_Surface *screen;

  screen = NULL;
  if (infos->inFile != NULL && infos->outFile != NULL)
    {
      if (is_bmp(infos->inFile))
	{
	  InitSDL(screen,0);
	  processAll(infos);
	  SDL_Quit();
	  printf("SDL closed.\n");
	}
      else
	{
	  help("extract");
	  wfree(infos);
	  exit(EXIT_SUCCESS);
	}
    }
}
