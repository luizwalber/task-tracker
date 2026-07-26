import { IsISO8601, IsNumber, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

export class UpdateTaskDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  name?: string;

  @IsOptional()
  @IsNumber()
  @Min(0.5)
  @Max(2)
  weight?: number;

  @IsOptional()
  @IsISO8601({ strict: true })
  startsOn?: string;

  @IsOptional()
  @IsISO8601({ strict: true })
  endsOn?: string;
}
