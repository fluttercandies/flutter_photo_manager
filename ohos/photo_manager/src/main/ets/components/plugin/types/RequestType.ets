
export  class RequestType {
  constructor(value: number) {
    this.value = value;
  }
  value: number;
  static readonly _imageValue = 1;
  static readonly _videoValue = 1 << 1;
  static readonly _audioValue = 1 << 2;
  static readonly all = new RequestType(
    RequestType._imageValue | RequestType._videoValue | RequestType._audioValue
  );
  static readonly common = new RequestType(
    RequestType._imageValue | RequestType._videoValue
  );
  static readonly image = new RequestType(RequestType._imageValue);
  static readonly video = new RequestType(RequestType._videoValue);
  static readonly audio = new RequestType(RequestType._audioValue);

  containsImage(): boolean {
    return (this.value & RequestType._imageValue) === RequestType._imageValue;
  }

  containsVideo(): boolean {
    return (this.value & RequestType._videoValue) === RequestType._videoValue;
  }

  containsAudio(): boolean {
    return (this.value & RequestType._audioValue) === RequestType._audioValue;
  }

  containsType(type: RequestType): boolean {
    return (this.value & type.value) === type.value;
  }

  add(type: RequestType): RequestType {
    return new RequestType(this.value | type.value);
  }

  subtract(type: RequestType): RequestType {
    return new RequestType(this.value ^ type.value);
  }

  shiftRight(bit: number): RequestType {
    return new RequestType(this.value >> bit);
  }

  shiftLeft(bit: number): RequestType {
    return new RequestType(this.value << bit);
  }

  static values: RequestType[] = [RequestType.image, RequestType.video, RequestType.audio];

  static fromTypes(types: RequestType[]): RequestType {
    let result = new RequestType(0);
    for (const type of types) {
      result = result.add(type);
    }
    return result;
  }

  equals(other: ESObject): boolean {
    return other instanceof RequestType && this.value === other.value;
  }

  hashCode(): number {
    return this.value;
  }

  toString(): string {
    return `${this.constructor.name}(${this.value})`;
  }
}
