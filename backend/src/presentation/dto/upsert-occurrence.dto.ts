import { IsIn } from 'class-validator';

const VALID_PERCENTAGES = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

export class UpsertOccurrenceDto {
  @IsIn(VALID_PERCENTAGES)
  percentage: number;
}
